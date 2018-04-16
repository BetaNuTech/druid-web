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
    self.memo += "(Completed #{msg})"
  end

  def calculate_score
    return 0 if completed_at.nil?

    score_multiplier = 1.0
    quick_turn_value = 10 * 60
    quick_turn_ratio = 0.25
    base_score = scheduled_action.engagement_policy_action.try(:score) || 1.0

    late = completed_at > expires_at
    turnaround = expires_at.to_i - completed_at.to_i
    time_score = expires_at.to_i - completed_at.to_i
    time_baseline = expires_at.to_i - created_at.to_i
    turnaround_ratio = time_score.to_f / time_baseline.to_f

    # Assign 1 point if late
    if late
      self.score = 1
      return score
    end

    # Completion in less than 1/4 the allotted time (or 10m, whichever greater)
    #   gives a 1.5x multiplier
    if turnaround_ratio <= quick_turn_ratio || turnaround <= quick_turn_value
      score_multiplier = 1.5
    end

    # Score is the EngagementPolicyAction.base_score multiplied by the completion
    #   multiplier
    self.score = ( base_score.to_f * score_multiplier.to_f ).round(0)

    return score
  end

  private
end
