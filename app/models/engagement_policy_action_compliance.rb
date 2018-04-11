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
  belongs_to :user, optional: true

  ### Scopes
  #scope :expired, ->{where("expired_at < ?", DateTime.now)}

  ### Validations
  validates :state, presence: true,
    inclusion: EngagementPolicyActionCompliance.state_names

  ### Callbacks
  ### Class Methods
  ### Instance Methods


  def set_completion_date
    if self.completed_at.nil?
      case self.state
      when 'completed', 'completed_retry'
        self.completed_at = self.scheduled_action.completed_at
      end
    end
  end

  def add_completion_memo
    if state == 'rejected'
      self.memo = "Rejected"
      return
    end
    if (expires_at > ( completed_at ))
      msg = "on time"
    else
      lateness = ( (completed_at.to_i - expires_at.to_i).to_f / 3600.0 ).round(1)
      msg = "#{lateness} hours after deadline"
    end
    self.memo = ""
    self.memo += " (Completed #{msg})"
  end

  def calculate_score
    #base_score = scheduled_action.engagement_policy_action.try(:score)
    # TODO
    self.score = 0
  end

  private
end
