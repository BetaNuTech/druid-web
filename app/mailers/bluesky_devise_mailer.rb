class BlueskyDeviseMailer < Devise::Mailer
  helper :application # gives access to all helpers defined within `application_helper`.
  include Devise::Controllers::UrlHelpers # Optional. eg. `confirmation_url`
  default template_path: 'devise/mailer' # to make sure that you mailer uses the devise views
  default from: "no-reply@#{ENV.fetch('SMTP_DOMAIN', 'mail.blue-sky.app')}"

  def confirmation_instructions(record, token, opts={})
    # Devise sends this for a new account AND for an email address change
    # (reconfirmable); the template branches the same way.
    opts[:subject] = if record.pending_reconfirmation?
                       "Please confirm your new Bluesky email address."
                     else
                       "Welcome to Bluesky! Please confirm your account."
                     end
    @name = record.name
    super
  end

end
