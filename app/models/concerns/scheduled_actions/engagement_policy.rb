module ScheduledActions
  module EngagementPolicy
    extend ActiveSupport::Concern

    included do

      attr_accessor :completion_message, :completion_action

      def update_compliance_record
        EngagementPolicyScheduler.new.handle_scheduled_action_completion(self)
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
            user: user,
            lead_action: lead_action,
            notable: target,
            reason: Reason.where(name: "Scheduled").first,
            content: note_content
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
        return personal_task? ? ( DateTime.now.utc + 1.day ) : engagement_policy_action.next_scheduled_attempt(this_attempt)
      end


    end
  end
end
