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
  audited
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
    { schedule_attributes: Schedule::ALLOWED_PARAMS }
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
      action: lead_action&.description || lead_action&.name,
      schedule: schedule.try(:long_datetime),
      state: state.try(:upcase) || '',
    }
    return "%{desc}: %{action} by %{schedule} [%{state}] " % parts
  end

  def conflicting
    return [] if schedule.duration.nil? || schedule.duration == 0

    # The time stored in the schedules table is automatically converted to UTC by ActiveRecord
    # before persistence to the database. The SQL condition must use timestamps in UTC
    #
    # This code assumes that the current value of Time.zone is the same as the Timezone of
    # the user that owns this ScheduledAction
    schedule_start = DateTime.new(schedule.date.year, schedule.date.month,
                                  schedule.date.day, schedule.time.utc.hour,
                                  schedule.time.utc.min)
    schedule_end = DateTime.new(schedule.date.year, schedule.date.month,
                                schedule.date.day, schedule.end_time.utc.hour,
                                schedule.end_time.utc.min)
    params = {
      scheduled_action_id: id,
      user_id: user_id,
      schedule_start: schedule_start,
      schedule_end: schedule_end
    }

    join_sql = "INNER JOIN schedules on schedules.schedulable_type = 'ScheduledAction' AND schedules.schedulable_id = scheduled_actions.id"
    id_filter = id.present? ? 'scheduled_actions.id != :scheduled_action_id' : '1=1'
    date_filter =<<~SQL
    (
      ( (schedules.date + schedules.time)::timestamp BETWEEN :schedule_start AND :schedule_end )
      OR
      ( (schedules.date + COALESCE(schedules.end_time, schedules.time))::timestamp BETWEEN :schedule_start AND :schedule_end )
    )
    SQL
    availability_filter = "( schedules.duration IS NOT NULL AND schedules.duration != 0)"

    found = user.scheduled_actions.
      joins(join_sql).
      where("#{id_filter} AND #{date_filter} AND #{availability_filter}", params)

    return found
  end

  def completed?
    return completed_at.present?
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
