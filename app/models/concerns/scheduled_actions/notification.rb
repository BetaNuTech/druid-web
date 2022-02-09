module ScheduledActions
  module Notification
    extend ActiveSupport::Concern

    included do

      validates_presence_of :notification_message, if: :notify?

      scope :pending_notification,
        -> { where(scheduled_actions: {notify: true, notified_at: nil}) }

      after_create :send_notification

      # Only notify Leads and if
      def wants_notification?
        target.is_a?(Lead) && ( notify? || lead_action&.notify? )
      end

      def notified?
        notified_at.present? && notified_at <= DateTime.current
      end

      def notification_message_template_data
        schedule_template_data = {
          'schedule_date' => schedule&.date&.strftime("%A, %B %-d, %Y"),
          'schedule_time' => schedule&.time&.strftime("%l:%M%p")
        }
        return (target&.message_template_data || {}).merge(schedule_template_data)
      end

      def notification_message_content(message_template)
        return message_template.body_with_data(notification_message_template_data)
      end

      def send_notification
        return false unless ( notify? && wants_notification? )
        return true if notified?
        target.message_types_available.each do |message_type|
          message_body = message_type === MessageType.active.email ?
                          notification_message :
                          ActionView::Base.full_sanitizer.sanitize(notification_message)
          message = Message.new_message(
            from: user,
            to: target,
            message_type: message_type,
            subject: 'Appointment Reminder',
            body: message_body
          )
          ( message.save! && message.deliver! ) rescue false
        end
        return true
      end

      def notification_email_recipient
        return target&.message_recipientid(message_type:  MessageType.email)
      end

    end
  end
end
