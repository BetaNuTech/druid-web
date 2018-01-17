module Leads
  module StateMachine
    extend ActiveSupport::Concern

    included do
      # https://github.com/aasm/aasm
      include AASM

      aasm column: :state do
        state :open, initial: true
        state :claimed
        state :converted
        state :disqualified

        event :claim do
          transitions from: :open, to: :claimed,
            after: ->(*args) { event_set_user(*args)}
        end

        event :abandon do
          transitions from: :claimed, to: :open,
            after: ->(*args) { event_clear_user(*args) }
        end

        event :convert do
          transitions from: [ :open, :claimed ], to: :converted,
            after: ->(*args) { set_priority_zero }
        end

        event :disqualify do
          transitions from: [ :open, :claimed, :converted ], to: :disqualified,
            after: ->(*args) { set_priority_zero }
        end

        event :requalify do
          transitions from: :disqualified, to: :open,
            after: ->(*args) { event_clear_user; set_priority_low }
        end

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
