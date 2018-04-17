# == Schema Information
#
# Table name: engagement_policy_actions
#
#  id                     :uuid             not null, primary key
#  engagement_policy_id   :uuid
#  lead_action_id         :uuid
#  description            :text
#  deadline               :decimal(, )
#  retry_count            :integer          default(0)
#  retry_delay            :decimal(, )      default(0.0)
#  retry_delay_multiplier :string           default("none")
#  score                  :decimal(, )      default(1.0)
#  active                 :boolean          default(TRUE)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

class EngagementPolicyAction < ApplicationRecord
  ### Class Concerns/Extensions

  ### Constants
  VALID_DELAY_MULTIPLIERS = %w{ none double nonlinear }

  ### Associations
  belongs_to :engagement_policy
  belongs_to :lead_action

  ### Scopes
  scope :active, -> { where(active: true)}

  ### Validations
  validates :description, :active, { presence: true }
  validates :deadline, :score,
    { numericality: { greater_than: 0 }, presence: true,  }
  validates :retry_count, :retry_delay,
    { numericality: true, presence: true,  }
  validates :retry_delay_multiplier, { presence: true, inclusion: VALID_DELAY_MULTIPLIERS }

  ### Callbacks

  ### Class Methods

  ### Instance Methods

  def next_scheduled_attempt(attempt)
    delay_multiplier = case retry_delay_modifier
      when 'none'
        1.0
      when 'double'
        2 * attempt.to_f
      when 'nonliner'
        2**attempt
      else
        1.0
      end

    now = DateTime.now.utc
    attempt_date = now + ( delay_multiplier * retry_delay )

    return attempt_date
  end

end
