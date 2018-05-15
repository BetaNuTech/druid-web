module Messages
  module DeliveryAdapters
    class ActionMailer

      def deliver(from:, to:, subject:, body:)
        ::ActionMailer::Base.mail(
          from: from,
          to: to,
          subject: subject,
          body: body
        ).deliver
      end

    end
  end
end
