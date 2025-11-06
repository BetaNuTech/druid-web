class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@#{ENV.fetch('SMTP_DOMAIN', 'mail.blue-sky.app')}"
  layout 'mailer'
end
