# == Schema Information
#
# Table name: message_delivery_adapters
#
#  id              :uuid             not null, primary key
#  message_type_id :uuid             not null
#  slug            :string           not null
#  name            :string           not null
#  description     :text
#  active          :boolean          default(TRUE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class MessageDeliveryAdapter < ApplicationRecord
  ### Class Concerns/Extensions
  include Seeds::Seedable

  ### Constants
  ### Associations
  belongs_to :message_type

  ### Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates_inclusion_of :active, in: [true, false]

  ## Scopes
  scope :active, -> { where(active: true) }

  ### Class Methods

  ### Instance Methods
end
