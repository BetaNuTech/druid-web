# == Schema Information
#
# Table name: property_agents
#
#  id          :uuid             not null, primary key
#  user_id     :uuid
#  property_id :uuid
#  active      :boolean          default(TRUE)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class PropertyAgent < ApplicationRecord
  ### Class Concerns/Extensions
  audited

  ### Constants
  ALLOWED_PARAMS = [:user_id, :property_id, :active, :id, :_destroy]

  ### Associations
  belongs_to :user
  belongs_to :property

  ### Validations
  validates :user_id, uniqueness: {scope: :property_id}

  ### Scopes
  scope :active, ->() { where(active: true) }

  ### Class Methods

  ### Instance Methods
end
