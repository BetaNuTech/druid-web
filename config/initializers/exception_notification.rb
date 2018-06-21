exception_recipients = ENV.fetch('EXCEPTION_RECIPIENTS', '').split(',').map(&:strip)

if exception_recipients.empty?
	Rails.logger.warn " *** EXCEPTION_RECIPIENTS envvar is not set. Error notification is disabled!"
else
	Rails.application.config.middleware.use ExceptionNotification::Rack,
		:email => {
			:email_prefix => "[Druid System Messages] ",
			:sender_address => %{"Druid Exception Notifier" <druid@bluestone-prop>},
			:exception_recipients => exception_recipients
		}
end
