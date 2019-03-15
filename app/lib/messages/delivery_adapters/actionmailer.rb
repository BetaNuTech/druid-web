module Messages
  module DeliveryAdapters
    class Actionmailer

      MESSAGE_DELIVERY_REPLY_TO_ENV='MESSAGE_DELIVERY_REPLY_TO'

      def base_senderid
        return ENV.fetch(MESSAGE_DELIVERY_REPLY_TO_ENV, 'default@example.com')
      end

      def deliver(from:, to:, subject:, body:)
        ::ActionMailer::Base.mail(
          from: from,
          to: to,
          subject: subject,
          body: body,
          content_type: 'text/html'
        ).deliver_later
      end

    end
  end
end
