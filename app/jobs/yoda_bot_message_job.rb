# Posts one plain line to a Slack channel as the corporate Yoda Bot (the
# same app that posts errors to #bluesky-errors). Used for operational
# notices such as blocked resident contacts (Leads::ResidentBlockLog).
class YodaBotMessageJob < ApplicationJob
  queue_as :low_priority

  def perform(channel:, text:)
    token = YodaBot::ErrorNotifier.token
    return if token.blank? || channel.blank? || text.blank?

    # No link_names: the text quotes caller data, which must never be able
    # to ping @channel or a user.
    Slack::Web::Client.new(token: token).chat_postMessage(channel: channel, text: text)
  rescue StandardError => e
    # Log only: a broken token or channel must not turn into an error loop
    Rails.logger.error "YodaBotMessageJob: could not post to #{channel} - #{e.class}: #{e.message}"
  end
end
