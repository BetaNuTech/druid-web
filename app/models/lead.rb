# == Schema Information
#
# Table name: leads
#
#  id              :uuid             not null, primary key
#  user_id         :uuid
#  lead_source_id  :uuid
#  title           :string
#  first_name      :string
#  last_name       :string
#  referral        :string
#  state           :string
#  notes           :text
#  first_comm      :datetime
#  last_comm       :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  property_id     :uuid
#  phone1          :string
#  phone2          :string
#  fax             :string
#  email           :string
#  priority        :integer          default("low")
#  phone1_type     :string
#  phone2_type     :string
#  phone1_tod      :string
#  phone2_tod      :string
#  dob             :datetime
#  id_number       :string
#  id_state        :string
#  remoteid        :string
#  middle_name     :string
#  conversion_date :datetime
#

class Lead < ApplicationRecord

  ### Class Concerns/Extensions
  audited
  include Leads::EngagementPolicy
  include Leads::StateMachine
  include Leads::Search

  ### Constants
  ALLOWED_PARAMS = [:lead_source_id, :property_id, :title, :first_name, :last_name, :referral, :state, :notes, :first_comm, :last_comm, :phone1, :phone1_type, :phone1_tod, :phone2, :phone2_type, :phone2_tod, :dob, :id_number, :id_state, :email, :fax, :user_id, :priority]
  PHONE_TYPES = ["Cell", "Home", "Work"]
  PHONE_TOD = [ "Any Time", "Morning", "Afternoon", "Evening"]

  ### Enums
  enum priority: { zero: 0, low: 1, medium: 2, high: 3, urgent: 4 }, _prefix: :priority

  ### Associations
  has_one :preference,
    class_name: 'LeadPreference',
    dependent: :destroy
  accepts_nested_attributes_for :preference
  belongs_to :source, class_name: 'LeadSource', foreign_key: 'lead_source_id', required: false
  belongs_to :property, required: false
  belongs_to :user, required: false
  has_many :comments, class_name: "Note", as: :notable, dependent: :destroy
  has_many :scheduled_actions, as: :target

  ### Scopes
  scope :ordered_by_created, -> {order(created_at: "ASC")} 

  ### Validations
  validates :first_name, presence: true
	validates :phone1, presence: true, unless: ->(lead){ lead.phone2.present? || lead.email.present? }
	validates :email, presence: true, unless: ->(lead){ lead.phone1.present? || lead.phone2.present? }
  validates :remoteid, uniqueness: { scope: :property_id, case_sensitive: false }, if: -> {remoteid.present?}

  ### Class Methods

  def self.for_agent(agent)
    where(user_id: agent.id)
  end

  ### Instance Methods

  def imported?
    return self.remoteid.present?
  end

  def name
    [title, first_name, last_name].join(' ')
  end

  def priority_value
    self.class.priorities[self.priority]
  end

  private

end
