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
#  deactivated            :boolean          default(FALSE)
#

class User < ApplicationRecord

  ### Class Concerns/Extensions
  include Users::Roles
  include Users::Profile
  include Users::Devise
  include Users::Teams
  include Users::Properties
  include Users::Tasks
  include Users::Messaging
  audited

  ### Constants
  ALLOWED_PARAMS = [:id, :email, :password, :password_confirmation, :role_id, :timezone, :deactivated]

  ### Associations
  has_many :leads
  has_many :messages
  has_many :contact_events, dependent: :destroy

  ### Validations

  ### Scopes
  scope :by_name_asc, -> {
    scope = includes(:profile).order("user_profiles.last_name ASC, user_profiles.first_name ASC")
    scope = scope.where(system_user: false) if column_names.include?('system_user')
    scope
  }
  scope :active, -> { 
    scope = where.not(deactivated: true)
    scope = scope.where(system_user: false) if column_names.include?('system_user')
    scope
  }
  scope :non_system, -> { 
    column_names.include?('system_user') ? where(system_user: false) : all
  }

  ### Callbacks
  after_save :deactivation_cleanup
  before_validation :prevent_system_user_deactivation, if: :system?

  ### Class Methods
  def self.system
    return nil unless column_names.include?('system_user')
    find_by(system_user: true)
  end

  ### Instance Methods

  def deactivated?
    deactivated || false
  end

  def deactivate!
    transaction do
      assignments.destroy_all
      update!(deactivated: true)
    end
    reload
  end

  def active_for_authentication?
    return true if system?
    super && !deactivated? && member_of_an_active_property?
  end

  def member_of_an_active_property?
    # Default to True for admin and corporate accounts
    # who do not need property membership
    return true if admin? || team_admin?

    properties.any?(&:active?)
  end

  def name
    if first_name.nil? && last_name.nil?
      email
    else
      _name = [name_prefix, first_name, last_name].compact.join(' ').strip
      _name.empty? ? email : _name
    end
  end

  def initials
    first_char = first_name ? first_name[0] : last_name[0]
    second_char = last_name ? last_name[0] : first_name[1]
    [first_char, second_char].join.upcase
  end

  def available_leads(skope=nil)
    return LeadPolicy::Scope.new(self, (skope || Lead).open).
            resolve.
            order("leads.priority DESC, leads.created_at ASC")
  end

  # User's leads which changed state from 'open' to 'prospect'
  def worked_leads(start_date: (Date.current - 7.days).beginning_of_day, end_date: DateTime.current)
    return Lead.includes(:lead_transitions).
              where(leads: { user_id: self.id }).
              where(lead_transitions: {
                      last_state: 'open',
                      current_state: 'prospect',
                      created_at: start_date..end_date})
  end

  # User's lead which changed state to 'approved'
  def closed_leads(start_date: (Date.current - 7.days).beginning_of_day, end_date: DateTime.current)
    return Lead.includes(:lead_transitions).
              where(leads: { user_id: self.id } ).
              where(lead_transitions: {
                current_state: 'approved',
                created_at: start_date..end_date })
  end


  def deactivation_cleanup
    return true unless deactivated?
    Rails.logger.warn('Reassigning all Leads for User[#{id}]')
    leads.active.each do |lead|
      if lead.property&.primary_agent&.present?
        lead.user_id = lead.property.primary_agent.id
        lead.save
      end
    end

    Rails.logger.warn('Reassigning all ScheduledActions for User[#{id}]')
    scheduled_actions.pending.each do |sa|
      if sa.target.respond_to?(:property) && sa.target.property.primary_agent.present?
        sa.user_id = sa.target.property.primary_agent.id
        sa.save
      end
    end
  end

  def login_timestamps(start_date: nil)
    start_date ||= 1.month.ago.beginning_of_month
    end_date = DateTime.current
    audits = Audited::Audit.where(
      created_at: start_date..end_date,
      auditable_type: 'User',
      auditable_id: id,
    )

    logins = []
    audits.each do |audit|
      last_sign_in = audit[:audited_changes].fetch('current_sign_in_at', [])&.last
      next unless last_sign_in
      logins <<  last_sign_in
    end
    logins
  end

  def system?
    return false unless self.class.column_names.include?('system_user')
    system_user
  end

  handle_asynchronously :deactivation_cleanup, queue: :low_priority

  def reassign_leads(user:)
    transaction do
      leads.in_progress.each do |lead|
        lead.reassign(user: user)
      end
    end
  end

  private

  def prevent_system_user_deactivation
    return unless self.class.column_names.include?('system_user')
    return unless system_user
    
    if deactivated_changed? && deactivated?
      errors.add(:base, "System user cannot be deactivated")
      throw :abort
    end
  end
end
