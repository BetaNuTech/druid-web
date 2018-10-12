# == Schema Information
#
# Table name: users
#
#  id                     :uuid             not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  confirmation_token     :string
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string
#  failed_attempts        :integer          default(0), not null
#  unlock_token           :string
#  locked_at              :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  role_id                :uuid
#  timezone               :string           default("UTC")
#

class User < ApplicationRecord

  ### Class Concerns/Extensions
  include Users::Roles
  include Users::Profile
  include Users::Devise
  include Users::Teams
  audited

  ### Constants
  ALLOWED_PARAMS = [:id, :email, :password, :password_confirmation, :role_id, :timezone]

  ### Associations
  has_many :leads
  has_many :scheduled_actions
  has_many :compliances, class_name: 'EngagementPolicyActionCompliance'
  has_many :engagement_policy_action_compliances
  has_many :messages

  ### Validations

  ## Scopes
  scope :by_name_asc, -> {
    includes(:profile).
    order("user_profiles.last_name ASC, user_profiles.first_name ASC")
  }

  ### Class Methods

  ### Instance Methods

  def name
    if first_name.nil? && last_name.nil?
      email
    else
      _name = [name_prefix, first_name, last_name].compact.join(' ').strip
      _name.empty? ? email : _name
    end
  end

  def score
    compliances.sum(:score)
  end

  def available_leads
    return LeadPolicy::Scope.new(self, Lead.open).
            resolve.
            order("leads.priority DESC, leads.created_at ASC")
  end

  def total_score
    engagement_policy_action_compliances.sum(:score)
  end

  def weekly_score
    engagement_policy_action_compliances.
      where(completed_at: (Date.today.beginning_of_week)..DateTime.now).
      sum(:score)
  end

  def tasks_completed(start_date: (Date.today - 7.days).beginning_of_day, end_date: DateTime.now)
    ScheduledAction.includes(:engagement_policy_action_compliance).
      where( engagement_policy_action_compliances: {completed_at: start_date..end_date},
             scheduled_actions: {user_id: id} )
  end

  def tasks_pending
    ScheduledAction.includes(:engagement_policy_action_compliance).
      where( engagement_policy_action_compliances: {state: 'pending'},
             scheduled_actions: {user_id: id} )
  end

  # User's leads which changed state from 'open' to 'prospect'
  def claimed_leads(start_date: (Date.today - 7.days).beginning_of_day, end_date: DateTime.now)
    return Lead.includes(:lead_transitions).
              where(leads: { user_id: self.id }).
              where(lead_transitions: {
                      last_state: 'open',
                      current_state: 'prospect',
                      created_at: start_date..end_date})
  end

  # User's lead which changed state to 'approved'
  def closed_leads(start_date: (Date.today - 7.days).beginning_of_day, end_date: DateTime.now)
    return Lead.includes(:lead_transitions).
              where(leads: { user_id: self.id } ).
              where(lead_transitions: {
                current_state: 'approved',
                created_at: start_date..end_date })
  end

end
