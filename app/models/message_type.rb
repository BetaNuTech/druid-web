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
  has_many :delivery_adapters, class_name: "MessageDeliveryAdapter"

  ### Validations
  validates :name, presence: true, uniqueness: true

  ## Scopes
  scope :active, -> { where(active: true) }

  ### Class Methods

  def self.email
    MessageType.where(name: EMAIL_TYPE_NAME).active.first
  end

  def self.sms
    MessageType.where(name: SMS_TYPE_NAME).active.first
  end

  ### Instance Methods

  def sms?
    name == SMS_TYPE_NAME
  end

  def email?
    name == EMAIL_TYPE_NAME
  end

  def has_subject?
    sms? ? false : true
  end

  def has_body?
    true
  end
end
