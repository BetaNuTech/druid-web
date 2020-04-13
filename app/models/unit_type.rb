# == Schema Information
#
# Table name: unit_types
#
#  id          :uuid             not null, primary key
#  name        :string
#  active      :boolean          default("true")
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  description :text
#  property_id :uuid
#  remoteid    :string
#  bathrooms   :integer
#  bedrooms    :integer
#  market_rent :decimal(, )      default("0.0")
#  sqft        :decimal(, )      default("0.0")
#

class UnitType < ApplicationRecord
  ### Class Concerns/Extensions
  audited

  ### Constants
  ALLOWED_PARAMS = [:id, :name, :description, :property_id, :bathrooms, :bedrooms, :market_rent, :sqft, :active]

  ### Validations
  validates :name,
    presence: true,
    uniqueness: {case_sensitive: false, scope: :property_id}

  ### Associations
  belongs_to :property
  delegate :name, to: :property, prefix: true

  ### Validations

  ### Scopes
  scope :active, -> {where(active: true)}

  ### Class Methods

  ### Instance Methods
  def size_summary
    "%sBR %sBA (%s sqft)" % [bedrooms, bathrooms, sqft]
  end
end
