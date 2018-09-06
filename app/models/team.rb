class Team < ApplicationRecord
  ### CONSTANTS
  ALLOWED_PARAMS = [:name, :description]

  ### Associations
  has_many :properties

  ### Validations
  validates :name, presence: true, uniqueness: true
end
