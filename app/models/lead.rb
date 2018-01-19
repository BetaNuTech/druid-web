# == Schema Information
#
# Table name: leads
#
#  id             :uuid             not null, primary key
#  user_id        :uuid
#  lead_source_id :uuid
#  title          :string
#  first_name     :string
#  last_name      :string
#  referral       :string
#  state          :string
#  notes          :text
#  first_comm     :datetime
#  last_comm      :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  property_id    :uuid
#  phone1         :string
#  phone2         :string
#  fax            :string
#  email          :string
#  priority       :integer          default("low")
#  phone1_type    :string
#  phone2_type    :string
#  phone1_tod     :string
#  phone2_tod     :string
#  dob            :datetime
#  id_number      :string
#  id_state       :string
#

class Lead < ApplicationRecord

  ### Class Concerns/Extensions
  include Leads::StateMachine
  audited

  ### Constants
  ALLOWED_PARAMS = [:lead_source_id, :property_id, :title, :first_name, :last_name, :referral, :state, :notes, :first_comm, :last_comm, :phone1, :phone1_type, :phone1_tod, :phone2, :phone2_type, :phone2_tod, :dob, :id_number, :id_state, :email, :fax, :user_id, :priority]
  PHONE_TYPES = ["Cell", "Home", "Work"]
  PHONE_TOD = [ "Any Time", "Morning", "Afternoon", "Evening"]
  US_STATES = [ ['AK', 'AK'], ['AL', 'AL'], ['AR', 'AR'], ['AZ', 'AZ'], ['CA', 'CA'], ['CO', 'CO'], ['CT', 'CT'], ['DC', 'DC'], ['DE', 'DE'], ['FL', 'FL'], ['GA', 'GA'], ['HI', 'HI'], ['IA', 'IA'], ['ID', 'ID'], ['IL', 'IL'], ['IN', 'IN'], ['KS', 'KS'], ['KY', 'KY'], ['LA', 'LA'], ['MA', 'MA'], ['MD', 'MD'], ['ME', 'ME'], ['MI', 'MI'], ['MN', 'MN'], ['MO', 'MO'], ['MS', 'MS'], ['MT', 'MT'], ['NC', 'NC'], ['ND', 'ND'], ['NE', 'NE'], ['NH', 'NH'], ['NJ', 'NJ'], ['NM', 'NM'], ['NV', 'NV'], ['NY', 'NY'], ['OH', 'OH'], ['OK', 'OK'], ['OR', 'OR'], ['PA', 'PA'], ['RI', 'RI'], ['SC', 'SC'], ['SD', 'SD'], ['TN', 'TN'], ['TX', 'TX'], ['UT', 'UT'], ['VA', 'VA'], ['VT', 'VT'], ['WA', 'WA'], ['WI', 'WI'], ['WV', 'WV'], ['WY', 'WY'] ]

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

  ### Validations
  validates :first_name, presence: true
	validates :phone1, presence: true, unless: ->(lead){ lead.phone2.present? || lead.email.present? }
	validates :email, presence: true, unless: ->(lead){ lead.phone1.present? || lead.phone2.present? }

  ### Class Methods

  ### Instance Methods
  def name
    [title, first_name, last_name].join(' ')
  end

  def priority_value
    self.class.priorities[self.priority]
  end

  private

end
