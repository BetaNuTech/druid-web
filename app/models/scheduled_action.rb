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
#  remoteid                               :string
#  article_id                             :uuid
#  article_type                           :string
#  notify                                 :boolean          default(FALSE)
#  notified_at                            :datetime
#  notification_message                   :text
#

class ScheduledAction < ApplicationRecord
  ### Class Concerns/Extensions
  audited
  acts_as_schedulable :schedule
  include ScheduledActions::Schedule
  include ScheduledActions::Article
  include ScheduledActions::EngagementPolicy
  include ScheduledActions::StateMachine
  include ScheduledActions::Notification

  ### Constants
  ALLOWED_PARAMS = [
    :id,
    :impersonate, :user_id, :lead_action_id, :reason_id,
    :description, :completion_message, :completion_action,
    :completion_retry_delay_value, :completion_retry_delay_unit,
    :target_id, :target_type, :article_id, :article_type,
    :notify, :notification_message,
    { schedule_attributes: Schedule::ALLOWED_PARAMS }
  ]

  ### Associations

  # Owner/responsible party
  belongs_to :user, optional: true

  # Target, usually a Lead
  belongs_to :target, polymorphic: true, optional: true

  # Optional origination ScheduledAction, if this is a follow-up
  belongs_to :originator, class_name: 'ScheduledAction', optional: true

  # Context and Reason for this ScheduledAction
  belongs_to :lead_action, optional: true
  belongs_to :reason, optional: true

  # Optional Policy Action that required this ScheduledAction
  belongs_to :engagement_policy_action, optional: true

  # Policy Action compliance record
  belongs_to :engagement_policy_action_compliance, optional: true, dependent: :destroy

  # Notes/Comments
  has_many :notes, as: :notable, dependent: :destroy

  ### Scopes
  scope :for_agent, ->(agent) { where(user_id: agent.id) }
  scope :for_property, ->(property) {
    user_ids = property.users.pluck(:id)
    self.where(user_id: user_ids).or(
      self.where(user_id: user_ids, target_type: 'Lead')
    )
  }
  scope :contact, ->() { includes(:lead_action).where(lead_actions: {is_contact: true} ) }
  scope :showings, ->() { where(lead_action_id: LeadAction.showing&.id) }
  scope :appointments, ->() { where(lead_action_id: [ LeadAction.showing&.id, LeadAction.meeting&.id ].compact) }

  ### Validations
  validates :state, presence: true, inclusion: ScheduledAction.state_names

  ### Callbacks
  before_save :validate_target

  ### Class Methods


  ### Instance Methods

  attr_accessor :impersonate

  # Used by ScheduledActions#index
  def start_time
    self.completed_at || self.schedule.try(:to_datetime) || self.created_at
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
    return "%{desc}: %{action} by %{schedule} [%{state}] " % summary_data
  end

  def summary_data
    if compliance_task?
      desc = 'Lead Task'
      target_name = target&.name || 'Deleted'
      target_link = target ? Rails.application.routes.url_helpers.full_url_for(target)  : '#'
    else
      desc = 'Personal Task'
      target_name = target.class.name
      target_link = Rails.application.routes.url_helpers.scheduled_action_url(self)
    end

    {
      desc: desc,
      action: lead_action&.description || lead_action&.name || description,
      reason: reason&.name,
      schedule: schedule.try(:long_datetime),
      state: state.try(:upcase) || '',
      target: target_name,
      target_link: target_link
    }
  end

  def activity_summary
    parts = {
      action: lead_action&.name,
      article: article.present? ? ( ' ' + article.name ) : '',
      target: target&.name,
      desc: description.present? ? ": #{description}" : '',
      state: state&.upcase
    }
    summary = "%{action}%{article} for %{target}%{desc} [%{state}]" % parts
    return summary.gsub('  ',' ')
  end

  def conflicting
    invalid_time = ( schedule.duration.nil? || schedule.duration == 0 ) ||
      schedule.date.nil? || schedule.time.nil?
    return [] if invalid_time

    schedule.end_time ||= schedule.time + schedule.duration.minutes

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
      where("state = 'pending' AND #{id_filter} AND #{date_filter} AND #{availability_filter}", params)

    return found
  end

  def completed?
    return completed_at.present?
  end

  def urgent?
    return false if start_time.nil?

    start_time <= Time.current + 1.day
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
