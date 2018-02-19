# == Schema Information
#
# Table name: unit_types
#
#  id         :uuid             not null, primary key
#  name       :string
#  active     :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class UnitType < ApplicationRecord
  ### Class Concerns/Extensions

  ### Constants
  ALLOWED_PARAMS = [:id, :name, :active]

  ### Validations
  validates :name,
    presence: true,
    uniqueness: {case_sensitive: false}

  ### Associations

  ### Validations

  ### Class Methods

  ### Instance Methods
end
