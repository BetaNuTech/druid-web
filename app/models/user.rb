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
#  sign_in_count          :integer          default("0"), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  confirmation_token     :string
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string
#  failed_attempts        :integer          default("0"), not null
#  unlock_token           :string
#  locked_at              :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  role_id                :uuid
#  timezone               :string           default("UTC")
#  deactivated            :boolean          default("false")
#

class User < ApplicationRecord

  ### Class Concerns/Extensions
  include Users::Roles
  include Users::Profile
  include Users::Devise
  include Users::Teams
  include Users::Properties
  include Users::Tasks
  audited

  ### Constants
  ALLOWED_PARAMS = [:id, :email, :password, :password_confirmation, :role_id, :timezone, :deactivated]

  ### Associations
  has_many :leads
  has_many :messages

  ### Validations

  ## Scopes
  scope :by_name_asc, -> {
    includes(:profile).
    order("user_profiles.last_name ASC, user_profiles.first_name ASC")
  }

  scope :active, -> { where.not(deactivated: true) }

  ### Class Methods

  ### Instance Methods
  
  def deactivated?
    deactivated || false
  end

  def deactivate!
    self.deactivated = true
    self.save
  end

  def active_for_authentication?
    super && !deactivated?
  end

  def name
    if first_name.nil? && last_name.nil?
      email
    else
      _name = [name_prefix, first_name, last_name].compact.join(' ').strip
      _name.empty? ? email : _name
    end
  end

  def available_leads
    return LeadPolicy::Scope.new(self, Lead.open).
            resolve.
            order("leads.priority DESC, leads.created_at ASC")
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
