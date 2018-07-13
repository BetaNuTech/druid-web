module Leads
  module StateMachine
    extend ActiveSupport::Concern

    CLAIMED_STATES = %w{prospect appointment application approved denied movein resident}
    CLOSED_STATES = %w{ disqualified abandoned resident exresident }

    class_methods do
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
        dummy = Lead.new(state: state1)
        events = dummy.aasm.events(:permitted => true).map{|event| {name: event.name, transitions: event.transitions.map{|t| [t.from, t.to]}}}
        event = events.select{|event| event[:transitions].any?{|transition| transition[0].to_s == state1.to_s && transition[1].to_s == state2.to_s} }.first
        return event.nil? ? nil : event[:name]
      end
    end

    included do
      # https://github.com/aasm/aasm
      include AASM


      aasm column: :state do
        state :open, initial: true
        state :prospect
        state :appointment
        state :application
        state :approved
        state :denied
        state :movein
        state :resident
        state :exresident
        state :disqualified
        state :abandoned

        after_all_events :after_all_events_callback

        event :abandon do
          transitions from: [ :prospect, :appointment, :application, :approved, :denied ], to: :abandoned,
            after: ->(*args) { event_clear_user(*args) }
        end

        event :apply do
          transitions from: [:prospect, :appointment], to: :application,
            after: -> (*args) { apply_event_callback }
        end

        event :approve do
          transitions from: [:application, :denied], to: :approved
        end

        event :claim do
          transitions from: [ :open, :exresident, :abandoned ], to: :prospect,
            after: ->(*args) { event_set_user(*args)}
        end

        event :deny do
          transitions from: [:application, :approved, :movein], to: :denied
        end

        event :discharge do
          transitions from: [:resident], to: :exresident
        end

        event :disqualify do
          transitions from: [ :open, :prospect, :appointment, :application, :denied ], to: :disqualified,
            after: ->(*args) { set_priority_zero }
        end

        event :lodge do
          transitions from: [:movein], to: :resident,
            after: ->(*args) { set_conversion_date; set_priority_zero }
        end

        event :move_in do
          transitions from: [:approved], to: :movein
        end

        event :schedule do
          transitions from: [:prospect], to: :appointment
        end

        event :requalify do
          transitions from: :disqualified, to: :open,
            after: ->(*args) { event_clear_user; set_priority_low }
        end

        event :release do
          transitions from: :prospect, to: :open,
            after: ->(*args) { event_clear_user; set_priority_urgent }
        end

      end

      def self.active
        where.not(state: CLOSED_STATES)
      end

      def event_set_user(claimant=nil)
        self.user = claimant if claimant.present?
      end

      def event_clear_user(claimant=nil)
        self.user = nil
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
        send_application_to_lead
      end

      def trigger_event(event_name:, user: false)
        event = event_name.to_sym
        if permitted_state_events.include?(event.to_sym)
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
        create_scheduled_actions # Leads::EngagementPolicy#create_scheduled_actions
      end

      def set_conversion_date
        self.conversion_date = DateTime.now
      end

    end

  end
end
