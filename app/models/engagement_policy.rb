# == Schema Information
#
# Table name: engagement_policies
#
#  id          :uuid             not null, primary key
#  property_id :uuid
#  lead_state  :string
#  description :text
#  version     :integer          default(0)
#  active      :boolean          default(TRUE)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class EngagementPolicy < ApplicationRecord
  ### Class Concerns/Extensions

  ### Constants

  ### Associations
  belongs_to :property, required: false

  ### Scopes
  scope :latest_version, -> { where(active: true).order(version: "DESC") }
  scope :for_property, ->(propertyid) { latest_version.where(property_id: [property_id, nil]) }

  ### Validations
  validates :lead_state, inclusion: Lead.aasm.states.map{|s| s.name.to_s}
  validates :description, presence: true
  validates :version, uniqueness: {scope: :property_id, message: "should be unique per Property"}

  ### Callbacks
  before_validation :assign_version

  ### Class Methods

  ### Instance Methods

  private

  def assign_version
    if (self.version == 0 || !self.version.present?)
      last_version = EngagementPolicy.
          where(property_id: self.property_id).
          maximum('version') || 0
      self.version = last_version + 1
    end
    true
  end
end
