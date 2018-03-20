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

  ### Validations
  validates :description, :active, { presence: true }
  validates :deadline, :retry_count, :retry_delay, :score,
    { numericality: { greater_than: 0 }, presence: true,  }
  validates :retry_delay_multiplier, { presence: true, inclusion: VALID_DELAY_MULTIPLIERS }

  ### Callbacks

  ### Class Methods

  ### Instance Methods

end
