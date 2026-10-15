module Users
  module Devise
    extend ActiveSupport::Concern

    included do
      # :omniauthable adds "Sign in with Google". Whether that path is actually
      # available is decided at runtime by GoogleSignIn.enabled?, not here; this
      # line only generates the routes. :database_authenticatable stays
      # permanently as the password fallback.
      devise :database_authenticatable, :lockable, :timeoutable, :confirmable, :recoverable, :rememberable, :trackable, :validatable,
             :omniauthable, omniauth_providers: [GoogleSignIn::PROVIDER.to_sym]

      #def send_devise_notification(notification, *args)
        #devise_mailer.send(notification, self, *args).deliver_later
      #end

      def password_required?
        confirmed? ? super : false
      end
    end

  end
end
