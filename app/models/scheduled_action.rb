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
  ALLOWED_PARAMS = [
    :impersonate, :user_id, :lead_action_id, :reason_id,
    :description, :completion_message, :completion_action,
    :completion_retry_delay_value, :completion_retry_delay_unit,
    :target_id, :target_type,
    { schedule_attributes: Schedulable::ScheduleSupport.param_names + [:duration, :end_time] }
  ]

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
  before_save :validate_target

  ### Class Methods


  ### Instance Methods

  attr_accessor :impersonate

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

  def summary
    parts = {
      desc: ( compliance_task? ? "Engagement Policy Task" : "Personal Task" ),
      action: lead_action.description || lead_action.name,
      schedule: schedule.try(:long_datetime),
      state: state.try(:upcase) || '',
    }
    return "%{desc}: %{action} by %{schedule} [%{state}] " % parts
  end

  private

  def validate_target
    if user && target_type.present?
      policy = (Object.const_get("#{target_type}Policy::Scope") rescue false)
      if policy
        if ( target == policy.new(user, Object.const_get(target_type).where(id: target_id)).resolve.first)
          return true
        else
          errors.add(:target, 'Invalid Target due to access permissions')
          return false
        end
      else
        return true
      end
    else
      return true
    end
  end
end
