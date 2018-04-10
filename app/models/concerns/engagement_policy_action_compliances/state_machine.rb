module EngagementPolicyActionCompliances
  module StateMachine
    extend ActiveSupport::Concern

    class_methods do
      def state_names
        EngagementPolicyActionCompliance.aasm.states.map{|s| s.name.to_s}
      end
    end

    included do
      # https://github.com/aasm/aasm
      include AASM

      aasm column: :state do
        state :pending, initial: true
        state :completed
        state :completed_retry
        state :expired
        state :rejected

        event :complete do
          transitions from: [:pending], to: "completed"
        end

        event :retry do
          transitions from: [:pending], to: "completed_retry"
        end

        event :expire do
          transitions from: [:pending, :completed_retry], to: :expired
        end

        event :reject do
          transitions from: [:pending, :completed_retry], to: :rejected
        end
      end
    end
  end
end
