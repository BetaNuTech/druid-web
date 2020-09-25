module Users
  module Messaging
    extend ActiveSupport::Concern

    PENDING_TASK_NOTIFICATION_TEMPLATE_NAME = 'System-PendingTaskNotification'

    included do

      def optout_email?
        false
      end

      def handle_message_delivery(*_args)
        # NOOP
        true
      end

      def message_template_data
        tasks_today = ScheduledAction.includes(:schedule, :lead_action, :target).
          for_agent(self).incomplete.having_schedule.
          where("schedules.date <= ?", Date.today)
        tasks_today_count = tasks_today.count
        tasks_today = tasks_today.sorted_by_due_desc.limit(20)
        summary_data = tasks_today.map(&:summary_data)
        #tasks_today = summary_data.map{|task| Struct.new(*task.keys).new(*task.values)}
        task_summaries = summary_data.map do |task|
          [
            "[%{schedule}] %{desc} for %{target}: %{action} (%{reason})" % task,
            task[:target_link]
          ]
        end
        {
          'id' => id,
          'name' => name,
          'tasks_today_count' => tasks_today_count,
          'tasks_today' => task_summaries,
          'profile_link' => Rails.application.routes.url_helpers.edit_user_url(self) + '#bluesky_appsettings'
        }
      end

      def message_recipientid(message_type: )
        return case message_type
          when -> (mt) { mt.email? }
            message_email_destination
          when -> (mt) { mt.sms? }
            message_sms_destination
          else
            'unknown'
          end
      end

      def message_sms_destination
        profile&.cell_phone
      end

      def message_email_destination
        email
      end

      def pending_task_notification_message
        message_template = MessageTemplate.where(name: Users::Messaging::PENDING_TASK_NOTIFICATION_TEMPLATE_NAME).first
        unless message_template.present?
          Rails.logger.error "*** Can't send pending task notification. Template is missing: '#{PENDING_TASK_NOTIFICATION_TEMPLATE_NAME}'"
          return nil
        end

        message_type = MessageType.email
        message = Message.new(
          message_type: message_type,
          message_template: message_template,
          threadid: nil,
          subject: nil,
          body: nil,
          classification: 'system',
          user: self,
          messageable: self,
          incoming: false
        )
        message.senderid = message.outgoing_senderid
        message.recipientid = message_recipientid(message_type: message_type)
        message.load_template
        message
      end


      def send_pending_task_notification
        message = pending_task_notification_message
        return false if message.nil?

        message.save!
        message.deliver!
        return true
      end

      handle_asynchronously :send_pending_task_notification
    end

    class_methods do

      def send_pending_task_notifications
        ::User.active.each do |user|
          active_leads = user.leads.active
          pending_tasks = ScheduledAction.includes(:schedule, :lead_action, :target).for_agent(user).due_today
          next unless active_leads.count > 1 && pending_tasks.count > 1
          user.send_pending_task_notification
        end
      end
    end
  end
end
