class LeadSource < ApplicationRecord
  has_many :leads

  validates :name, :incoming, :slug, :active,
    presence: true
  validates :name, :slug, uniqueness: true
end
