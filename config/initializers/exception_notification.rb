# Omit sensitive data from exception notification
Rails.application.config.filter_parameters +=
	[:password, :session, :warden, :secret, :salt, :cookie, :csrf]

exception_recipients = ENV.fetch('EXCEPTION_RECIPIENTS', '').split(',').map(&:strip)
exception_host = ENV.fetch('APPLICATION_HOST', 'unknown')

if ErrorNotification.enabled?
	# Post every reported error to #bluesky-errors as the corporate Yoda Bot -- see
	# YodaBot::ErrorNotifier. A lambda, not the class itself, so the constant is
	# resolved when an error is reported, not autoloaded during boot.
	unless Rails.env.test?
		ExceptionNotifier.add_notifier(:yoda_slack, ->(exception, options) { YodaBot::ErrorNotifier.call(exception, options) })
	end

	middleware_options = {
		ignore_exceptions: ExceptionNotifier.ignored_exceptions + %w[
			ActionController::InvalidAuthenticityToken
		]
	}

	if exception_recipients.empty?
		msg = " *** EXCEPTION_RECIPIENTS envvar is not set. Error notification email is disabled!"
		Rails.logger.error msg
		puts msg
	else
		middleware_options[:email] = {
			:email_prefix => "Exception raised on #{exception_host} ",
			:sender_address => %{"BlueSky Errors (#{exception_host})" <no-reply@#{ENV.fetch('SMTP_DOMAIN', 'mail.blue-sky.app')}>},
			:exception_recipients => exception_recipients,
			:sections => %w{request environment backtrace}
		}
	end

	Rails.application.config.middleware.use ExceptionNotification::Rack, **middleware_options
else
	msg = " *** Exception notification is disabled. Set envvar EXCEPTION_NOTIFIER_ENABLED=true"
	Rails.logger.error msg
	puts msg
end
