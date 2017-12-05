# == Schema Information
#
# Table name: lead_sources
#
#  id         :uuid             not null, primary key
#  name       :string
#  incoming   :boolean
#  slug       :string
#  active     :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

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
