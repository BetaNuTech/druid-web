module Messages
  module DeliveryAdapters
    module Cloudmailin
      class EmailParser

        def self.match?(data)
          return true
        end

        def self.parse(data)
          to = data.fetch("envelope",{}).fetch("to")
          from = data.fetch("envelope",{}).fetch("from")
          subject = data.fetch("headers",{}).fetch("Subject")
          body = data.fetch(:plain,nil) || data.fetch(:html,nil) || ''
          message_template_id = nil
          message_type_id = MessageType.email.try(:id)
          delivered_at = DateTime.now

          to_addr = params.fetch(:envelope, {}).fetch(:to,'') || ""
          threadid = ( _to_addr.split('@').first || "" ).split("+").last

          if (last_message = Message.where(threadid: threadid))
            user_id = last_message.user_id
            messageable_id = last_message.messageable_id
            messageable_type = last_message.messageable_type
          else
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
            message_type_id: message_type_id
          }

        end

      end
    end
  end
end
