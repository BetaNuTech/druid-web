module Messages
  module DeliveryAdapters
    module Cloudmailin
      class EmailParser

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

          recipientid = to = ( data.fetch(:envelope).fetch(:to, '') rescue '')
          senderid = from = ( data.fetch(:envelope).fetch(:from, '') rescue '')
          subject = ( data.fetch(:headers,{}).fetch(:Subject, '') rescue '' )
          body = data.fetch(:plain, nil) || data.fetch(:html, nil) || ''
          message_template_id = nil
          message_type_id = MessageType.email.try(:id)
          delivered_at = DateTime.current

          threadid = ( recipientid.split('@').first || "" ).split("+").last

          if (last_message = Message.where(threadid: threadid).order("delivered_at DESC").first)
            if last_message.messageable.present? && last_message.messageable.respond_to?(:user_id)
              user_id = last_message.messageable.user_id
            else
              user_id = nil
            end
            user_id ||= last_message.user_id
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
            message_type_id: message_type_id,
            threadid: threadid
          }

        end

      end
    end
  end
end
