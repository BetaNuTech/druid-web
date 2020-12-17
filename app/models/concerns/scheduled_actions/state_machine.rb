module ScheduledActions
  module StateMachine
    extend ActiveSupport::Concern

    class_methods do
      def state_names
        ScheduledAction.aasm.states.map{|s| s.name.to_s}
      end
    end

    included do
      # https://github.com/aasm/aasm
      include AASM

      scope :incomplete, -> {where.not(state: ['completed', 'completed_retry', 'rejected', 'expired'])}
      scope :complete, -> {where.not(state: ['pending'])}
      scope :finished, -> {where(state: [ 'completed', 'completed_retry' ])}
      scope :valid, -> {where.not(state: 'rejected')}

      def is_completed?
        ['completed', 'completed_retry', 'rejected', 'expired'].include?(state)
      end

      aasm column: :state do
        state :pending
        state :completed
        state :completed_retry
        state :expired
        state :rejected

        after_all_events -> (*args) { after_all_events_callback(*args) }

        event :complete do
          transitions from: [:pending], to: :completed,
            after: :target_completion
        end

        event :retry do
          transitions from: [:pending], to: :completed_retry,
            after: :create_retry_record
        end

        event :expire do
          transitions from: [:pending, :completed_retry], to: :expired
        end

        event :reject do
          transitions from: [:pending, :completed_retry], to: :rejected
        end

        event :restore do
          transitions from: [:completed, :completed_retry, :rejected, :expired], to: :pending,
            after: :reset_completion_status
        end
      end

      def after_all_events_callback(user=nil)
        self.transaction do
          set_completion_time
          update_compliance_record(user: user)
        end
      end

      def set_completion_time
        case self.state
        when 'completed', 'completed_retry'
          if !self.completed_at.present?
            self.completed_at = DateTime.now
            self.save
          end
        end
      end

      def trigger_event(event_name:, user: nil)
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

      def selectable_state_events
        base_events = permitted_state_events
        omit = []
        if final_attempt?
          omit << :retry
        end
        return base_events - omit
      end

      def target_completion
        if target.respond_to?(:handle_scheduled_action_completion)
          target.handle_scheduled_action_completion(self)
        end
      end

    end
  end
end
