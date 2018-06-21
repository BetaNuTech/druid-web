class ErrorNotification
  class << self

    def enabled?
      # Enabled by default
      return ENV.fetch('EXCEPTION_NOTIFIER_ENABLED', 'true').downcase == 'true'
    end

    def send(exception, data={})
      if ErrorNotification.enabled?
        ExceptionNotifier.notify_exception(exception, data: data)
      end
    end
  end
end
