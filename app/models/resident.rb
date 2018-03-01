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
  ALLOWED_PARAMS = [:id, :lead_id, :property_id, :unit_id, :status, :dob, :title, :first_name, :middle_name, :last_name, :address1, :address2, :city, :state, :zip, :country]
  INVALID_UNIT_PROPERTY_ERROR = "Unit must belong to same Property"

  ### Associations
  belongs_to :lead
  belongs_to :property
  belongs_to :unit
  has_one :detail, class_name: 'ResidentDetail', dependent: :destroy

  ### Validations
  validates :residentid,
    presence: true, uniqueness: {case_sensitive: false}
  validates :first_name, :last_name,
    presence: true
  validates :status,
    presence: true
  validate :unit_belongs_to_property

  ### Callbacks
  before_validation :assign_residentid

  ### Class Methods

  ### Instance Methods

  private

  def unit_belongs_to_property
    if unit.property_id != property_id
      errors[:base] << INVALID_UNIT_PROPERTY_ERROR
    end
  end

  def assign_residentid
    newid = "R%s" % Array.new(8){rand(10)}.join
    self.residentid ||= newid
  end

end
