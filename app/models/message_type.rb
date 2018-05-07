# == Schema Information
#
# Table name: message_types
#
#  id          :uuid             not null, primary key
#  name        :string           not null
#  description :text
#  active      :boolean          default(TRUE), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class MessageType < ApplicationRecord
  ### Class Concerns/Extensions
  include Seeds::Seedable

  ### Constants
  SMS_TYPE_NAME = 'SMS'
  EMAIL_TYPE_NAME = 'Email'

  ### Associations
  has_many :message_templates

  ### Validations
  validates :name, presence: true

  ## Scopes
  scope :active, -> { where(active: true) }

  ### Class Methods

  def self.email
    MessageType.where(name: EMAIL_TYPE_NAME).first
  end

  def self.sms
    MessageType.where(name: SMS_TYPE_NAME).first
  end

  ### Instance Methods

  def sms?
    name == SMS_TYPE_NAME
  end

  def email?
    name == EMAIL_TYPE_NAME
  end
end
