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
  include ScheduledActions::StateMachine
  acts_as_schedulable :schedule

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

  ### Scopes

  ### Validations
  validates :state, presence: true, inclusion: ScheduledAction.state_names

  ### Callbacks

  ### Accessors

  attr_accessor :completion_message, :completion_action

  ### Class Methods

  def self.having_schedule
    self.joins("INNER JOIN schedules ON schedules.schedulable_type = 'ScheduledAction' AND schedules.schedulable_id = scheduled_actions.id")
  end

  def self.upcoming
    return self.incomplete.having_schedule
  end

  def self.previous
    skope = self.incomplete.having_schedule.
      where("schedules.date < ?", Date.today).
      or(self.having_schedule.complete)
    return skope
  end

  def self.with_start_date(date)
    start_date = ( Date.parse(date).beginning_of_month rescue (Date.today.beginning_of_month) )
    self.having_schedule.
      where("schedules.date >= ?", start_date).
      or(self.having_schedule.where(state: 'pending'))
  end

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
