module Messages
  module DeliveryAdapters
    module Twilioadapter
      class SmsParser

        #TODO

        def self.match?(data)
          return true
        end

        def self.parse(in_data)
          data = case in_data
            when Hash, ActionController::Parameters
              in_data
            else
              {}
            end

          recipientid = to = data.fetch('To','')
          senderid = from = data.fetch('From','')
          subject = '(No Subject)'
          body = data.fetch('Body','(No Body)')
          message_template_id = nil
          message_type_id = MessageType.sms.try(:id)
          delivered_at = DateTime.now

          last_message = Message.sent.where(recipientid: senderid).
            order(created_at: 'desc').first
          if last_message.present?
            threadid = last_message.threadid
            user_id = last_message.user_id
            messageable_id = last_message.messageable_id
            messageable_type = last_message.messageable_type
          else
            threadid = nil
            user_id = nil
            messageable_id = nil
            messageable_type = nil
          end

          return {
            messageable_id: messageable_id,
            messageable_type: messageable_type,
            user_id: user_id,
            state: 'sent',
            senderid: senderid,
            recipientid: recipientid,
            message_template_id: message_template_id,
            subject: subject,
            body: body,
            delivered_at: delivered_at,
            message_type_id: message_type_id,
            threadid: threadid
          }

        end

      end
    end
  end
end
