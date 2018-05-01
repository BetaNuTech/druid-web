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

  def self.email
    MessageType.where(name: 'Email').first
  end

  def self.sms
    MessageType.where(name: 'SMS').first
  end

  ### Instance Methods
end
