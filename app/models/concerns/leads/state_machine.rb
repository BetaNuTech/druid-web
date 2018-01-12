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
          transitions from: :open, to: :claimed
        end

        event :abandon do
          transitions from: :claimed, to: :open
        end

        event :convert do
          transitions from: [ :open, :claimed ], to: :converted
        end

        event :disqualify do
          transitions from: [ :open, :claimed, :converted ], to: :disqualified
        end

        event :requalify do
          transitions from: :disqualified, to: :open
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
