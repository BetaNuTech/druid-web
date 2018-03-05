# == Schema Information
#
# Table name: residents
#
#  id          :uuid             not null, primary key
#  lead_id     :uuid
#  property_id :uuid
#  unit_id     :uuid
#  residentid  :string
#  status      :string
#  dob         :date
#  title       :string
#  first_name  :string
#  middle_name :string
#  last_name   :string
#  address1    :string
#  address2    :string
#  city        :string
#  state       :string
#  zip         :string
#  country     :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Resident < ApplicationRecord
  ### Class Concerns/Extensions
  audited

  ### Constants
  ALLOWED_PARAMS = [:lead_id, :property_id, :unit_id, :status, :dob, :title, :first_name, :middle_name, :last_name, :address1, :address2, :city, :state, :zip, :country]
  INVALID_UNIT_PROPERTY_ERROR = "Unit must belong to same Property"
  STATUS_OPTIONS = ["current", "former"]

  ### Associations
  belongs_to :lead, optional: true
  belongs_to :property
  belongs_to :unit
  has_one :detail, class_name: 'ResidentDetail', dependent: :destroy
  accepts_nested_attributes_for :detail

  ### Validations
  validates :first_name, :last_name,
    presence: true
  validates :residentid,
    presence: true, uniqueness: {case_sensitive: false}
  validates :status,
    presence: true, inclusion: {in: STATUS_OPTIONS}
  validate :unit_belongs_to_property

  ### Callbacks
  after_initialize :assign_detail
  before_validation :assign_residentid

  ### Class Methods

  def self.generate_residentid
    return "R%s" % Array.new(8){rand(10)}.join
  end

  ### Instance Methods

  def name
    [title, first_name, middle_name, last_name].compact.join(" ")
  end

  def salutation
    [title, last_name].join(" ")
  end

  private

  def unit_belongs_to_property
    if unit.property_id != property_id
      errors[:base] << INVALID_UNIT_PROPERTY_ERROR
    end
  end

  def assign_residentid
    self.residentid ||= Resident.generate_residentid
  end

  def assign_detail
    self.detail ||= ResidentDetail.new
  end


end
