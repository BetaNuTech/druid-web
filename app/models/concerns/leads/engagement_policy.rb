module Leads
  module EngagementPolicy
    extend ActiveSupport::Concern

    APPLICATION_EMAIL_NAME_WALKIN = 'Invite to Online Application - Walkin - HTML'
    APPLICATION_EMAIL_NAME_ONLINE = 'Invite to Online Application - Online Lead - HTML'
    APPLICATION_COMMENT_ACTION_NAME = 'Email Rental Application'
    APPLICATION_COMMENT_REASON_NAME = 'Pipeline Event'

    included do
      after_create :create_scheduled_actions
      after_save :ensure_scheduled_action_ownership

      def create_scheduled_actions
        EngagementPolicyScheduler.new.create_scheduled_actions(lead: self)
      end

      def reassign_scheduled_actions
        return true unless self.user

        EngagementPolicyScheduler.new.reassign_lead_agent(lead: self, agent: self.user)
      end

      def ensure_scheduled_action_ownership
        if self.saved_change_to_attribute?(:user_id)
          reassign_scheduled_actions
        end
      end

      def send_rental_application
        #if walk_in?
          #message_template_name = APPLICATION_EMAIL_NAME_WALKIN
        #else
          message_template_name = APPLICATION_EMAIL_NAME_ONLINE
        #end

        message_template = MessageTemplate.where(name: message_template_name).first
        errors = {errors: []}

        if message_template
          message = Message.new_message(
            from: User.system,
            to: self,
            message_type: MessageType.email,
            message_template: message_template,
          )
          message.save
          message.deliver!
          message.reload
          comment_content = "SENT: #{message_template_name}"
        else
          # Cannot send Message: send Error Notification
          message = Message.new()
          error_message = "Lead Pipeline: Could not send application to Lead[#{self.id}]"
          errors[:errors] << error_message
          error = StandardError.new(error_message)
          if message_template.nil?
            errors[:errors] << "Missing Message Template: '#{message_template_name}'"
          end
          ErrorNotification.send(error,errors)
          comment_content = "NOT SENT: #{message_template_name} -- #{errors[:errors].join('; ')}"
        end

        create_rental_application_comment(content: comment_content, agent: agent)

        return message.deliveries.last
      end

      def create_rental_application_comment(content:, agent:)
        note_lead_action = LeadAction.where(name: APPLICATION_COMMENT_ACTION_NAME).first
        note_reason = Reason.where(name: APPLICATION_COMMENT_REASON_NAME).first
        note = Note.create!( # create_event_note
          lead_action: note_lead_action,
          notable: self,
          reason: note_reason,
          content: content,
          classification: 'system'
        )
      end

    end
  end
end
