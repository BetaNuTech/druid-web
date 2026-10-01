class YodaBotErrorJob < ApplicationJob
  queue_as :low_priority

  # Posts one error to #bluesky-errors as the corporate Yoda Bot. Enqueued by
  # YodaBot::ErrorNotifier, which also explains the setup.
  def perform(fingerprint:, channel:, error_class:, message:, location: nil, origin: nil, data: nil, host: nil)
    token = YodaBot::ErrorNotifier.token
    return if token.blank? || channel.blank?

    suppressed = ErrorAlert.claim_post(fingerprint)
    return if suppressed.nil?

    text = YodaBot::ErrorMessage.new(
      error_class: error_class, message: message, location: location,
      origin: origin, data: data, host: host
    ).text(suppressed)

    # No link_names: the text quotes exception messages, which must never be
    # able to ping @channel or a user.
    Slack::Web::Client.new(token: token).chat_postMessage(channel: channel, text: text)
  rescue StandardError => e
    # Log only. Reporting this through ErrorNotification would come straight
    # back here as another error to post -- a loop if the token or channel is broken.
    Rails.logger.error "YodaBotErrorJob: could not post to #{channel} - #{e.class}: #{e.message}"
  end
end
