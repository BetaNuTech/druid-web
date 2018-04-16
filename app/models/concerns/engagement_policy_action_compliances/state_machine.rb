module EngagementPolicyActionCompliances
  module StateMachine
    extend ActiveSupport::Concern

    class_methods do
      def state_names
        EngagementPolicyActionCompliance.aasm.states.map{|s| s.name.to_s}
      end

      def completed_states
        EngagementPolicyActionCompliance.state_names - ['pending']
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

        after_all_events :after_all_events_callback

        event :complete do
          transitions from: [:pending], to: :completed
        end

        event :retry do
          transitions from: [:pending], to: :completed_retry
        end

        event :expire do
          transitions from: [:pending, :completed_retry], to: :expired
        end

        event :reject do
          transitions from: [:pending, :completed_retry], to: :rejected
        end
      end

      def after_all_events_callback
        return true unless EngagementPolicyActionCompliance.completed_states.include?(self.state)
        set_completion_date
        calculate_score
        add_completion_memo
        save
      end
    end
  end
end
