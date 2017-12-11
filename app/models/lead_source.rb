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

  # Private Methods

  private

  def assign_api_token
    self.api_token ||= Digest::SHA256.hexdigest(Time.now.to_s + rand.to_s)[0..31]
  end

end
