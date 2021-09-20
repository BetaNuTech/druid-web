class ErrorNotification
  class << self

    def enabled?
      # Enabled by default
      return ENV.fetch('EXCEPTION_NOTIFIER_ENABLED', 'true').downcase == 'true'
    end

    def send(exception, data={})
      if ErrorNotification.enabled? && !Rails.env.test?
        hostname = ENV.fetch('APPLICATION_HOST','Unknown Host')
        x_data = data.merge({ host: hostname })
        ExceptionNotifier.notify_exception(exception, data: x_data)
      end
    end
  end
end
