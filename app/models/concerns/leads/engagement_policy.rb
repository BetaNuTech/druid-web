module Leads
  module EngagementPolicy
    extend ActiveSupport::Concern

    included do
      after_create :create_scheduled_actions
      after_save :ensure_scheduled_action_ownership

      def create_scheduled_actions
        EngagementPolicyScheduler.new.create_scheduled_actions(lead: self)
      end

      def reassign_scheduled_actions
        EngagementPolicyScheduler.new.reassign_lead_agent(lead: self, agent: self.user)
      end

      def ensure_scheduled_action_ownership
        if self.saved_change_to_attribute?(:user_id)
          reassign_scheduled_actions
        end
      end

      def send_rental_application
        if optout?
          Rails.logger.warn "Rental application was not emailed to Lead[#{id}] due to opt-out."
          return true
        end

        if walk_in?
          message_template_name = 'Invite to Online Application - Walkin - HTML'
        else
          message_template_name = 'Invite to Online Application - Online Lead - HTML'
        end

        message_template = MessageTemplate.where(name: message_template_name).first
        message_user = user || property.managers.first

        if message_template && message_user
          message = Message.new_message(
            from: message_user,
            to: self,
            message_type: MessageType.email,
            message_template: message_template,
          )
          message.deliver!
          message.reload
        else
          # Cannot send Message: send Error Notification
          message = Message.new()
          errors = {errors: []}
          error = StandardError.new("Lead Pipeline: Could not send application to Lead[#{self.id}]")
          if message_template.nil?
            errors[:errors] << "Missing Message Template: '#{message_template_name}'"
          end
          if message_user.nil?
            errors[:errors] << "Lead has no agent, and property has no manager"
          end
          ErrorNotification.send(error,errors)
        end

        return message.deliveries.last
      end
    end
  end
end
