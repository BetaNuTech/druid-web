module Messages
  module DeliveryAdapters
    class Actionmailer

      MESSAGE_DELIVERY_REPLY_TO_ENV='MESSAGE_DELIVERY_REPLY_TO'

      def base_senderid
        return ENV.fetch(MESSAGE_DELIVERY_REPLY_TO_ENV, 'default@example.com')
      end

      def deliver(from:, to:, subject:, body:, reply_to: nil)
        begin
          mail_options = {
            from: from,
            to: to,
            subject: subject,
            body: body,
            content_type: 'text/html'
          }
          
          # Add reply_to if provided
          mail_options[:reply_to] = reply_to if reply_to.present?
          
          ::ActionMailer::Base.mail(mail_options).deliver
          
          # Return success response
          return { success: true, log: "Message successfully delivered via ActionMailer" }
        rescue => e
          # Return failure response
          return { success: false, log: "ActionMailer delivery failed: #{e.message}" }
        end
      end

    end
  end
end
