# == Schema Information
#
# Table name: unit_types
#
#  id         :uuid             not null, primary key
#  name       :string
#  active     :boolean          default(TRUE)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class UnitType < ApplicationRecord
  ### Class Concerns/Extensions

  ### Constants
  ALLOWED_PARAMS = [:id, :name, :description, :property_id, :active]

  ### Validations
  validates :name,
    presence: true,
    uniqueness: {case_sensitive: false, scope: :property_id}

  ### Associations
  belongs_to :property
  delegate :name, to: :property, prefix: true

  ### Validations

  ### Class Methods

  ### Instance Methods
end
