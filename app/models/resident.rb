# == Schema Information
#
# Table name: residents
#
#  id           :uuid             not null, primary key
#  lead_id      :uuid
#  property_id  :uuid
#  unit_id      :uuid
#  residentid   :string
#  status       :string
#  dob          :date
#  title        :string
#  first_name   :string
#  middle_name  :string
#  last_name    :string
#  address1     :string
#  address2     :string
#  city         :string
#  state        :string
#  zip          :string
#  country      :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  relationship :string
#  yardi_status :string
#

class Resident < ApplicationRecord
  ### Class Concerns/Extensions
  audited

  ### Constants
  ALLOWED_PARAMS = [:lead_id, :property_id, :unit_id, :status, :dob, :title, :first_name, :middle_name, :last_name, :address1, :address2, :city, :state, :zip, :country, :relationship, :yardi_status]
  INVALID_UNIT_PROPERTY_ERROR = "Unit must belong to same Property"
  STATUS_OPTIONS = ["current", "former"]
  # Manually entered residents get an R + 8 digits id (generate_residentid);
  # Yardi imports use Yardi's own codes (t0225446, r0023191, t0225446-519322)
  MANUAL_RESIDENTID = /\AR\d{8}\z/
  MANUAL_RESIDENTID_SQL = '^R[0-9]{8}$'.freeze # the same, as a PostgreSQL regular expression
  # Household member types a lead may legitimately share contact details
  # with while still being a prospect for a unit of their own
  CONTACT_ONLY_EXEMPT_RELATIONSHIPS = ['Guarantor'].freeze

  ### Associations
  belongs_to :lead, optional: true
  belongs_to :property
  # Optional: NONRES tenants (parking, office suites) and units Bluesky does
  # not know about have no Unit record
  belongs_to :unit, optional: true
  has_one :detail, class_name: 'ResidentDetail', dependent: :destroy
  accepts_nested_attributes_for :detail
  has_many :lead_referrals, as: :referrable

  ### Validations
  validates :first_name, :last_name,
    presence: true
  validates :residentid,
    presence: true, uniqueness: {case_sensitive: false}
  validates :status,
    presence: true, inclusion: {in: STATUS_OPTIONS}
  validate :unit_belongs_to_property

  ### Callbacks
  #after_initialize :assign_detail
  before_validation :assign_residentid

  ### Class Methods

  def self.generate_residentid
    return "R%s" % Array.new(8){rand(10)}.join
  end

  def self.current
    where(status: 'current')
  end

  ### Instance Methods

  def name
    [title, first_name, middle_name, last_name].compact.join(" ")
  end

  def salutation
    [title, last_name].join(" ")
  end

  def name_and_unit
    "#{name} (#{unit&.name || '?'})"
  end

  def unit_label
    unit&.unit.presence || '?'
  end

  # Imported from Yardi (as opposed to entered by hand in Bluesky)
  def yardi_import?
    residentid.present? && !residentid.match?(MANUAL_RESIDENTID)
  end

  private

  def unit_belongs_to_property
    return unless unit.present?
    if unit.property_id != property_id
      errors.add(:base, INVALID_UNIT_PROPERTY_ERROR)
    end
  end

  def assign_residentid
    self.residentid ||= Resident.generate_residentid
  end

  def assign_detail
    self.detail ||= ResidentDetail.new
  end


end
