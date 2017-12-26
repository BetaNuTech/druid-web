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
#  api_token  :string
#

class LeadSource < ApplicationRecord

  # A LeadSource 'slug' also identifies the parser
  DEFAULT_SLUG = 'Druid'

  # Associations
  has_many :leads
  has_many :listings, class_name: 'PropertyListing', foreign_key: 'source_id'
  has_many :properties, through: :listings

  # Validations
  validates :name, :slug, :api_token,
    presence: true
  validates :name, :api_token, uniqueness: true

  # Scopes
  scope :active, -> { where(active: true) }

  # Callbacks
  before_validation :assign_api_token

  # Class Methods

  def self.default
    self.active.where(slug: DEFAULT_SLUG).first
  end

  # Instance Methods

  def listings_by_property_name
    listings.includes("property").order("properties.name ASC")
  end

  # Private Methods

  private

  def assign_api_token
    self.api_token ||= Digest::SHA256.hexdigest(Time.now.to_s + rand.to_s)[0..31]
  end

end
