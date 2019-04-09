# == Schema Information
#
# Table name: rental_types
#
#  id         :uuid             not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class RentalType < ApplicationRecord
  ### Class Concerns/Extensions
  audited

  ### Constants

  ### Validations
  validates :name, uniqueness: {case_sensitive: false}, presence: true

  ## Associations
  # TODO: has_many :units

  ### Class Methods

  ### Instance Methods
end
