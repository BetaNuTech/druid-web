# == Schema Information
#
# Table name: error_alerts
#
#  id               :uuid             not null, primary key
#  fingerprint      :string           not null
#  last_posted_at   :datetime
#  suppressed_count :integer          default(0), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Rate limit for the #bluesky-errors Slack posts (see YodaBot::ErrorNotifier).
#
# One bad sync can raise the same error once per property or lead, and Slack
# allows roughly one post per second per channel, so each distinct error posts
# at most once per WINDOW and the next post says how many repeats were held back.
#
# This lives in the database rather than Rails.cache so that every web and
# worker dyno shares the same limit.
class ErrorAlert < ApplicationRecord
  WINDOW = 15.minutes

  # Returns the number of repeats suppressed since the last post when this
  # occurrence should be posted, or nil when it falls inside the window (in which
  # case it is counted instead).
  def self.claim_post(fingerprint, now: Time.current)
    alert = create_or_find_by!(fingerprint: fingerprint)

    alert.with_lock do
      if alert.last_posted_at.nil? || alert.last_posted_at <= now - WINDOW
        suppressed = alert.suppressed_count
        alert.update!(last_posted_at: now, suppressed_count: 0)
        suppressed
      else
        alert.update!(suppressed_count: alert.suppressed_count + 1)
        nil
      end
    end
  end
end
