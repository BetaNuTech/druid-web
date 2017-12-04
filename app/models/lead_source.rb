class LeadSource < ApplicationRecord
  # Associations
  has_many :leads

  # Validations
  validates :name, :incoming, :slug, :active,
    presence: true
  validates :name, :slug, uniqueness: true

  # Scopes
  scope :active, -> { where(active: true) }

  # Class Methods
  
  # Instance Methods

  # Private Methods
  
  private

end
