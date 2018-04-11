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

  ### Associations
  belongs_to :user, optional: true
  belongs_to :target, polymorphic: true, optional: true
  belongs_to :orginator, class_name: 'ScheduledAction', optional: true
  belongs_to :lead_action, optional: true
  belongs_to :reason, optional: true
  belongs_to :engagement_policy_action, optional: true
  belongs_to :engagement_policy_action_compliance, optional: true, dependent: :destroy

  ### Scopes

  ### Validations
  validates :state, presence: true, inclusion: ScheduledAction.state_names

  ### Callbacks

  ### Class Methods

  ### Instance Methods

  private
end
