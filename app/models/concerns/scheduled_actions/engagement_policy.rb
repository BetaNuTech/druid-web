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

    end
  end
end
