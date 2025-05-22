# Omit sensitive data from exception notification
Rails.application.config.filter_parameters +=
	[:password, :session, :warden, :secret, :salt, :cookie, :csrf]

exception_recipients = ENV.fetch('EXCEPTION_RECIPIENTS', '').split(',').map(&:strip)
exception_host = ENV.fetch('APPLICATION_HOST', 'unknown')

if exception_recipients.empty?
	msg = " *** EXCEPTION_RECIPIENTS envvar is not set. Error notification is disabled!"
	Rails.logger.error msg
	puts msg
elsif ErrorNotification.enabled?
	Rails.application.config.middleware.use ExceptionNotification::Rack,
		:email => {
		:email_prefix => "Exception raised on #{exception_host} ",
		:sender_address => %{"BlueSky Errors (#{exception_host})" <bluesky@bluecrestresidential.com>},
		:exception_recipients => exception_recipients,
		:sections => %w{request environment backtrace}
	},
	slack: {
		webhook_url: ENV.fetch('SLACK_ERROR_NOTIFICATION_WEBHOOK', ''),
		channel: '#bluesky-errors',
		additional_parameters: {
			#icon_url: 'http://image.jpg',
			mrkdwn: true
		}
	}
else
	msg = " *** Exception notification is disabled. Set envvar EXCEPTION_NOTIFIER_ENABLED=true"
	Rails.logger.error msg
	puts msg
end
