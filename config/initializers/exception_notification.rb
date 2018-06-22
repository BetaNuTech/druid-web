exception_recipients = ENV.fetch('EXCEPTION_RECIPIENTS', '').split(',').map(&:strip)

if exception_recipients.empty?
  msg = " *** EXCEPTION_RECIPIENTS envvar is not set. Error notification is disabled!"
	Rails.logger.warn msg
  puts msg
elsif ErrorNotification.enabled?
	Rails.application.config.middleware.use ExceptionNotification::Rack,
		:email => {
			:email_prefix => "[Druid System Messages] ",
			:sender_address => %{"Druid Exception Notifier" <druid@bluestone-prop>},
			:exception_recipients => exception_recipients
		}
else
  msg = " *** Exception notification is disabled. Set envvar EXCEPTION_NOTIFIER_ENABLED=true"
  Rails.logger.warn msg
  puts msg
end
