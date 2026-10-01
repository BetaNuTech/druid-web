require 'digest'

module YodaBot
  # ExceptionNotifier notifier that sends every reported error to #bluesky-errors
  # as the corporate Yoda Bot. It replaces exception_notification's own Slack
  # notifier, which used a Slack incoming webhook that Slack has deprecated.
  #
  # Registered in config/initializers/exception_notification.rb, so it sees both
  # the uncaught request exceptions from ExceptionNotification::Rack and the
  # explicit ErrorNotification.send calls.
  #
  # This runs inline wherever the error happened, possibly inside a transaction,
  # so it does no more than enqueue a job. The rate limit (ErrorAlert) and the
  # Slack call both happen in YodaBotErrorJob.
  class ErrorNotifier
    MESSAGE_LIMIT = 1000
    DATA_LIMIT = 500
    FRAME_PATTERN = /\A(?<file>[^:]+):(?<line>\d+)(?::in [`'](?<function>.+)')?/.freeze

    def self.token
      ENV['SLACK_CORP_YODABOT_OAUTH_TOKEN']
    end

    # Set ERROR_SLACK_CHANNEL blank to stop the posts.
    def self.channel
      ENV.fetch('ERROR_SLACK_CHANNEL', '#bluesky-errors')
    end

    def self.enabled?
      token.present? && channel.present?
    end

    def self.call(exception, options = {})
      return unless enabled?

      data = options[:data].is_a?(Hash) ? options[:data] : {}
      frame = app_frame(exception.backtrace)

      YodaBotErrorJob.perform_later(
        fingerprint: fingerprint(exception, frame),
        channel: channel,
        error_class: exception.class.name.to_s,
        message: exception.message.to_s.truncate(MESSAGE_LIMIT),
        location: location(frame),
        origin: origin(options[:env]),
        data: describe_data(data.except(:host)),
        host: (data[:host] || ENV['APPLICATION_HOST']).to_s
      )
    rescue StandardError => e
      # Never call ErrorNotification from here: that would re-enter this notifier.
      Rails.logger.error "YodaBot::ErrorNotifier: could not enqueue error post - #{e.class}: #{e.message}"
    end

    # The first backtrace frame in our own code, as { file:, line:, function: }.
    def self.app_frame(backtrace)
      return nil if backtrace.blank?

      Rails.backtrace_cleaner.clean(backtrace).each do |raw|
        match = FRAME_PATTERN.match(raw)
        next unless match && match[:file].start_with?('app/', 'lib/')

        return { file: match[:file], line: match[:line], function: match[:function] }
      end
      nil
    end

    # Exception class + file + method, deliberately without the message (which
    # often carries a property code or id) or the line number, so the same
    # failure repeating across properties counts as one error. Exceptions built
    # with StandardError.new(msg) have no backtrace, so for those the message is
    # all there is; its digits are blanked so ids still group together.
    def self.fingerprint(exception, frame)
      parts = [exception.class.name]
      if frame
        parts += [frame[:file], frame[:function]]
      else
        parts << exception.message.to_s.gsub(/\d+/, '#').truncate(200)
      end
      Digest::SHA1.hexdigest(parts.join('|'))
    end

    def self.location(frame)
      return nil if frame.nil?

      ["#{frame[:file]}:#{frame[:line]}", frame[:function].presence].compact.join(' in ')
    end

    # "leads#show" for request exceptions.
    def self.origin(env)
      controller = env && env['action_controller.instance']
      return nil unless controller.respond_to?(:controller_path)

      "#{controller.controller_path}##{controller.action_name}"
    end

    def self.describe_data(data)
      return nil if data.blank?

      data.map { |key, value| "#{key}: #{value}" }.join(', ').truncate(DATA_LIMIT)
    end
  end
end
