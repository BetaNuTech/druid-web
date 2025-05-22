module Messages
  module DeliveryAdapters
    class Actionmailer

      MESSAGE_DELIVERY_REPLY_TO_ENV='MESSAGE_DELIVERY_REPLY_TO'

      def base_senderid
        return ENV.fetch(MESSAGE_DELIVERY_REPLY_TO_ENV, 'default@example.com')
      end

      def deliver(from:, to:, subject:, body:)
        begin
          ::ActionMailer::Base.mail(
            from: from,
            to: to,
            subject: subject,
            body: body,
            content_type: 'text/html'
          ).deliver
          
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
