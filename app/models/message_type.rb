# == Schema Information
#
# Table name: message_types
#
#  id          :uuid             not null, primary key
#  name        :string
#  description :text
#  active      :boolean
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class MessageType < ApplicationRecord
  ### Class Concerns/Extensions
  include Seeds::Seedable

  ### Constants
  ### Associations
  ### Validations

  ## Scopes
  scope :active, -> { where(active: true) }

  ### Class Methods

  ### Instance Methods
end
