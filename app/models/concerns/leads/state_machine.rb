module Leads
  module StateMachine
    extend ActiveSupport::Concern

    CLAIMED_STATES = %w{prospect appointment application approved denied movein resident}
    CLOSED_STATES = %w{ disqualified abandoned resident exresident }

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


        event :abandon do
          transitions from: [ :prospect, :appointment, :application, :approved, :denied ], to: :abandoned,
            after: ->(*args) { event_clear_user(*args) }
        end

        event :apply do
          transitions from: [:appointment], to: :application
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
            after: ->(*args) { set_priority_zero }
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

    end

  end
end
