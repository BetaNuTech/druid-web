module Users
  module Devise
    extend ActiveSupport::Concern

    included do
      def send_devise_notification(notification, *args)
        devise_mailer.send(notification, self, *args).deliver_later
      end
    end

  end
end
