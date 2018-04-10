# == Schema Information
#
# Table name: engagement_policy_action_compliances
#
#  id                  :uuid             not null, primary key
#  scheduled_action_id :uuid
#  user_id             :uuid
#  state               :string           default("pending")
#  expires_at          :datetime
#  completed_at        :datetime
#  score               :decimal(, )
#  memo                :text
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

class EngagementPolicyActionCompliance < ApplicationRecord
  ### Class Concerns/Extensions
  include EngagementPolicyActionCompliances::StateMachine

  ### Constants

  ### Associations
  belongs_to :scheduled_action
  belongs_to :user

  ### Scopes
  #scope :expired, ->{where("expired_at < ?", DateTime.now)}

  ### Validations
  validates :state, presence: true,
    inclusion: EngagementPolicyActionCompliance.state_names

  ### Callbacks
  ### Class Methods
  ### Instance Methods

  private
end
