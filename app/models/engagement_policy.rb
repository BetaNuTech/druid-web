# == Schema Information
#
# Table name: engagement_policies
#
#  id          :uuid             not null, primary key
#  property_id :uuid
#  lead_state  :string
#  description :text
#  version     :integer          default("0")
#  active      :boolean          default("true")
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class EngagementPolicy < ApplicationRecord
  ### Class Concerns/Extensions

  ### Constants

  ### Associations
  belongs_to :property, required: false
  has_many :actions, class_name: 'EngagementPolicyAction', dependent: :destroy

  ### Scopes
  scope :latest_version, -> { where(active: true).order(version: "DESC") }
  scope :for_property, ->(propertyid) { where(property_id: [propertyid, nil]) }
  scope :for_state, ->(state) { where(lead_state: [state, nil]) }
  scope :without_property, -> { where(property_id: nil)}

  ### Validations
  validates :lead_state, inclusion: Lead.state_names, presence: true
  validates :description, presence: true
  validates :version, uniqueness: {scope: [ :property_id, :lead_state ], message: "should be unique per Property per Lead state"}

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
