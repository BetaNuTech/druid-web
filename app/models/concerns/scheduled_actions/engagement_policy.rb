module ScheduledActions
  module EngagementPolicy
    extend ActiveSupport::Concern

    included do

      attr_accessor :completion_message, :completion_action, :completion_retry_delay_value, :completion_retry_delay_unit

      def update_compliance_record(user: nil)
        EngagementPolicyScheduler.new.handle_scheduled_action_completion(self, user: user)
      end

      def reset_completion_status
        EngagementPolicyScheduler.new.reset_completion_status(self)
        add_subject_completion_note("Reset Task/Scheduled Action")
      end

      def create_retry_record
        EngagementPolicyScheduler.new.create_retry_record(self)
      end

      def add_subject_completion_note(message=nil)
        note = nil
        if target.present? && target.respond_to?(:notes)
          note_content = summary + " -- " + ( message || completion_message || "")
          note = Note.new(
            lead_action: lead_action,
            notable: target,
            reason: reason,
            content: note_content,
            classification: 'system'
          )
          note.save
        else
          note = nil
        end
        return note
      end

      def max_attempts
        return 999 unless engagement_policy_action.present?
        return engagement_policy_action.retry_count + 1
      end

      def final_attempt?
        return false unless engagement_policy_action.present?
        return attempt >= max_attempts
      end

      def can_retry?
        return !final_attempt?
      end

      def personal_task?
        return ( user_id.present? && !compliance_task? )
      end

      def compliance_task?
        return (engagement_policy_action_compliance_id.present? && engagement_policy_action_id.present?)
      end

      def next_scheduled_attempt(this_attempt=nil)
        if completion_retry_delay_value.present? && completion_retry_delay_unit.present?
          # Use override delay information
          retry_value = [completion_retry_delay_value.to_i, 1].max
          case completion_retry_delay_unit
          when 'hours'
            return (DateTime.now.utc + retry_value.hours)
          when 'days'
            return (DateTime.now.utc + retry_value.days)
          else
            # The Retry Unit is invalid, so default to using the Policy retry_delay
            self.completion_retry_delay_unit = nil
            return next_scheduled_attempt(self)
          end
        else
          # If this is a personal task, return Now + 1 day
          # If this is a Compliance Task, return the date as dictated by Policy
          return personal_task? ? ( DateTime.now.utc + 1.day ) : engagement_policy_action.next_scheduled_attempt(this_attempt)
        end
      end


    end
  end
end
