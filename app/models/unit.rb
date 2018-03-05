# == Schema Information
#
# Table name: units
#
#  id             :uuid             not null, primary key
#  property_id    :uuid
#  unit_type_id   :uuid
#  rental_type_id :uuid
#  unit           :string
#  floor          :integer
#  sqft           :integer
#  bedrooms       :integer
#  description    :text
#  address1       :string
#  address2       :string
#  city           :string
#  state          :string
#  zip            :string
#  country        :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class Unit < ApplicationRecord
  ### Constants
  ALLOWED_PARAMS = [:id, :property_id, :unit_type_id, :rental_type_id, :unit, :floor, :sqft, :bedrooms, :address1, :address2, :city, :state, :zipcode, :country]

  ### Class Concerns/Extensions
  audited

  ### Associations
  belongs_to :property
  belongs_to :rental_type
  belongs_to :unit_type
  has_one :resident
  delegate :name, to: :property, prefix: true
  delegate :name, to: :unit_type, prefix: true
  delegate :name, to: :rental_type, prefix: true

  ### Validations
  validates :unit,
    presence: true,
    uniqueness: { case_sensitive: false, scope: :property_id }

  ### Class Methods

  ### Instance Methods
end
