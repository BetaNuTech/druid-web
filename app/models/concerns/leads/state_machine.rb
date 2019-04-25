module Leads
  module StateMachine
    extend ActiveSupport::Concern

    CLAIMED_STATES = %w{prospect application approved denied movein resident}
    CLOSED_STATES = %w{ disqualified abandoned resident exresident future }

    class_methods do

      def early_pipeline
        where(state: ['open', 'prospect', 'application'])
      end

      def active
        where.not(state: CLOSED_STATES)
      end

      def pending_revisit
        where(state: 'future').
          where("follow_up_at IS NOT NULL AND follow_up_at <= ?", DateTime.now)
      end

      def state_names
        Lead.aasm.states.map{|s| s.name.to_s}
      end

      def compare_states(state1=nil, state2=nil)
        return nil if state1.nil? || state2.nil?

        index1 = Lead.state_names.index(state1.to_s)
        index2 = Lead.state_names.index(state2.to_s)

        if index1 > index2
          return 1
        elsif index1 == index2
          return 0
        else
          return -1
        end
      end

      def event_name_for_transition(from: , to: )
        state1 = from
        state2 = to
        return nil if state1.nil? || state2.nil?
        dummy = Lead.new(state: state1, classification: 'lead', email: 'me@here.com')
        events = dummy.aasm.events(:permitted => true).map{|event| {name: event.name, transitions: event.transitions.map{|t| [t.from, t.to]}}}
        event = events.select{|event| event[:transitions].any?{|transition| transition[0].to_s == state1.to_s && transition[1].to_s == state2.to_s} }.first
        return event.nil? ? nil : event[:name]
      end

      def process_followups
        pending_revisit.each do |lead|
          Rails.logger.warn "Lead #{lead.id} is ready to revisit"
          lead.trigger_event(event_name: 'revisit')
        end
      end
    end

    included do
      has_many :lead_transitions
      attr_accessor :ignore_incomplete_tasks, :transition_memo, :skip_event_notifications

      after_create :create_initial_transition

      # https://github.com/aasm/aasm
      include AASM

      aasm column: :state do
        state :open, initial: true
        state :prospect
        state :application
        state :approved
        state :denied
        state :movein
        state :resident
        state :exresident
        state :disqualified
        state :abandoned
        state :future

        after_all_events :after_all_events_callback

        event :abandon do
          transitions from: [ :prospect, :application, :approved, :denied ], to: :abandoned,
            after: ->(*args) { event_clear_user(*args); clear_all_tasks }
        end

        event :apply do
          transitions from: [:prospect], to: :application,
            after: -> (*args) { apply_event_callback },
            guard: :may_apply?
        end

        event :approve do
          transitions from: [:application, :denied], to: :approved,
            guard: :may_progress?
        end

        event :claim do
          transitions from: [ :open, :exresident, :abandoned ], to: :prospect,
            after: ->(*args) { event_set_user(*args); force_complete_all_tasks(*args) }
        end

        event :deny do
          transitions from: [:application, :approved, :movein], to: :denied
        end

        event :discharge do
          transitions from: [:resident], to: :exresident,
            guard: :may_progress?
        end

        event :disqualify do
          transitions from: [ :open, :prospect, :application, :denied, :approved, :movein, :resident ], to: :disqualified,
            after: ->(*args) { set_priority_zero }
        end

        event :lodge do
          transitions from: [:movein], to: :resident,
            after: ->(*args) { set_conversion_date; set_priority_zero },
            guard: :may_progress?
        end

        event :move_in do
          transitions from: [:approved], to: :movein,
            guard: :may_progress?
        end

        event :requalify do
          transitions from: :disqualified, to: :open,
            after: ->(*args) { event_clear_user; set_priority_low }
        end

        event :release do
          transitions from: :prospect, to: :open,
            after: ->(*args) { event_clear_user; set_priority_urgent }
        end

        event :postpone do
          transitions from: [:open, :prospect, :application], to: :future,
            after: -> (*args) {clear_all_tasks; event_clear_user; set_priority_low}
        end

        event :revisit do
          transitions from: :future, to: :open,
            after: -> (*args) {unset_follow_up_at}
        end

      end

      def event_set_user(claimant=nil)
        self.user = claimant if claimant.present?
      end

      def event_clear_user(claimant=nil)
        self.user = nil
      end

      def force_complete_all_tasks(claimant=nil)
        if claimant.present?
          scheduled_actions.pending.each do |action|
            action.user_id = claimant.id
            action.complete!
          end
        end
      end

      def clear_all_tasks
        scheduled_actions.destroy_all
      end

      def may_apply?
        is_lead? && may_progress? && email.present?
      end

      # Lead is permitted to change state
      def may_progress?
        return all_tasks_completed?
      end

      def set_priority_zero
        self.priority = "zero"
      end

      def set_priority_low
        self.priority = "low"
      end

      def set_priority_urgent
        self.priority = "urgent"
      end

      def apply_event_callback
        return true if skip_event_notifications
        send_rental_application # Leads::EngagementPolicy#send_application_to_lead
      end

      def trigger_event(event_name:, user: false)
        event = event_name.to_sym
        if permitted_state_events.include?(event)
          self.aasm.fire(event, user)
          return self.save
        else
          return false
        end
      end

      def permitted_state_events
        aasm.events(permitted: true).map(&:name)
      end

      def permitted_states
        aasm.states(permitted: true).map(&:name)
      end

      def after_all_events_callback
        create_lead_transition
        create_lead_transition_note
        create_scheduled_actions # Leads::EngagementPolicy#create_scheduled_actions
      end

      def set_conversion_date
        self.conversion_date = DateTime.now
      end

      def create_initial_transition
        create_lead_transition(last_state: 'none', current_state: self.state)
      end

      def create_lead_transition(last_state: nil, current_state: nil)
        self.lead_transitions << self.lead_transitions.build(
          last_state: last_state || aasm.from_state,
          current_state: current_state || aasm.to_state,
          classification: self.classification || 'lead',
          memo: self.transition_memo
        )
      end

      def create_lead_transition_note
        self.comments << self.comments.build(
          user: user,
          reason: Reason.where(name: "Pipeline Event").last,
          content: "Lead transitioned from %s to %s.%s" % [
            ( aasm.from_state&.capitalize || '?' ),
            ( aasm.to_state&.capitalize || '?' ),
            (transition_memo.present? ? " -- Memo: #{transition_memo}": '')
          ]
        )
      end

      def unset_follow_up_at
        self.follow_up_at = nil
      end

    end

  end
end
