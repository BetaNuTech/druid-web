# == Schema Information
#
# Table name: scheduled_actions
#
#  id                                     :uuid             not null, primary key
#  user_id                                :uuid
#  target_id                              :uuid
#  target_type                            :string
#  originator_id                          :uuid
#  lead_action_id                         :uuid
#  reason_id                              :uuid
#  schedule_id                            :uuid
#  engagement_policy_action_id            :uuid
#  engagement_policy_action_compliance_id :uuid
#  description                            :text
#  completed_at                           :datetime
#  state                                  :string           default("pending")
#  attempt                                :integer          default(1)
#  created_at                             :datetime         not null
#  updated_at                             :datetime         not null
#

class ScheduledAction < ApplicationRecord
  ### Class Concerns/Extensions
  acts_as_schedulable :schedule
  include ScheduledActions::Schedule
  include ScheduledActions::EngagementPolicy
  include ScheduledActions::StateMachine

  ### Constants
  ALLOWED_PARAMS = [:user_id, :lead_action_id, :reason_id, :description]

  ### Associations
  belongs_to :user, optional: true
  belongs_to :target, polymorphic: true, optional: true
  belongs_to :originator, class_name: 'ScheduledAction', optional: true
  belongs_to :lead_action, optional: true
  belongs_to :reason, optional: true
  belongs_to :engagement_policy_action, optional: true
  belongs_to :engagement_policy_action_compliance, optional: true, dependent: :destroy
  has_many :notes, as: :notable, dependent: :destroy

  ### Scopes
  scope :for_agent, ->(agent) { where(user_id: agent.id) }

  ### Validations
  validates :state, presence: true, inclusion: ScheduledAction.state_names

  ### Callbacks

  ### Class Methods


  ### Instance Methods

  def start_time
    self.schedule.try(:date)
  end

  def target_subject(user=nil)
    if target.present?
      if target === user
        "Personal Task"
      else
        "%s (%s)" % [ target.try(:name), target_type ]
      end
    else
      'None'
    end
  end

  private
end
