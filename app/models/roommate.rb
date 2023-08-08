# == Schema Information
#
# Table name: roommates
#
#  id            :uuid             not null, primary key
#  lead_id       :uuid
#  first_name    :string
#  last_name     :string
#  phone         :string
#  email         :string
#  relationship  :integer          default("other")
#  sms_allowed   :boolean          default(FALSE)
#  email_allowed :boolean          default(TRUE)
#  occupancy     :integer          default("resident")
#  remoteid      :string
#  notes         :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
class Roommate < ApplicationRecord
  # Class Concerns/Extensions
  include Leads::Messaging
  audited

  ### Constants
  ALLOWED_PARAMS = [:first_name, :last_name, :occupancy, :relationship, :phone, :email, :responsible, :minor, :sms_allowed, :email_allowed, :notes]

  ### Enums
  enum occupancy: { resident: 0, guarantor: 1, child: 2}
  enum relationship: { other: 0, spouse: 1, dependent: 2}

  ### Associations
  belongs_to :lead
  has_one :preference, class_name: 'RoommatePreference', dependent: :destroy
  has_one :property, through: :lead
  has_one :user, through: :lead

  ### Validations
  validates :first_name, :last_name, presence: {message: 'must be provided'}
	validates :phone, presence: {message: 'or email must be provided'}, unless: ->(){ self.email.present? }
	validates :email, presence: {message: 'or phone number must be provided'}, unless: ->(){ self.phone.present? }

  ### Callbacks
  before_validation :format_phones

  ### Class Methods

  ### Instance Methods

  def responsible?
    %w{resident guarantor}.include? occupancy
  end

  def guarantor?
    occupancy == 'guarantor'
  end

  def spouse?
    occupancy == 'resident' && relationship == 'spouse'
  end

  def minor?
    occupancy == 'child'
  end

  def shortid
    id.to_s.gsub('-','')[0..19]
  end

  def name
    [first_name, last_name].compact.join(' ').strip
  end

  private

  def format_phones
    self.phone = PhoneNumber.format_phone(self.phone) if self.phone.present?
  end

end
