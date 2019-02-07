# Omit sensitive data from exception notification
Rails.application.config.filter_parameters +=
  [:password, :session, :warden, :secret, :salt, :cookie, :csrf]

exception_recipients = ENV.fetch('EXCEPTION_RECIPIENTS', '').split(',').map(&:strip)
exception_host = ENV.fetch('APPLICATION_HOST', 'unknown')

if exception_recipients.empty?
  msg = " *** EXCEPTION_RECIPIENTS envvar is not set. Error notification is disabled!"
  Rails.logger.warn msg
  puts msg
elsif ErrorNotification.enabled?
  Rails.application.config.middleware.use ExceptionNotification::Rack,
    :email => {
    :email_prefix => "[Druid System Messages (#{exception_host})]",
      :sender_address => %{"Druid Exception Notifier (#{exception_host})" <druid@bluestone-prop.com>},
      :exception_recipients => exception_recipients,
      :sections => %w{request environment backtrace}
  }
else
  msg = " *** Exception notification is disabled. Set envvar EXCEPTION_NOTIFIER_ENABLED=true"
  Rails.logger.warn msg
  puts msg
end
