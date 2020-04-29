# == Schema Information
#
# Table name: message_types
#
#  id          :uuid             not null, primary key
#  name        :string           not null
#  description :text
#  active      :boolean          default("true"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  html        :boolean          default("false")
#

class MessageType < ApplicationRecord
  ### Class Concerns/Extensions
  include Seeds::Seedable
  audited

  ### Constants
  SMS_TYPE_NAME = 'SMS'
  EMAIL_TYPE_NAME = 'Email'
  SMS_MESSAGING_DISABLED_FLAG='SMS_MESSAGING_DISABLED'
  EMAIL_MESSAGING_DISABLED_FLAG='EMAIL_MESSAGING_DISABLED'

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

  def self.sms_messaging_disabled?
    %w{1 true t yes y}.include?(ENV.fetch(SMS_MESSAGING_DISABLED_FLAG, false).to_s.downcase)
  end

  def self.email_messaging_disabled?
    %w{1 true t yes y}.include?(ENV.fetch(EMAIL_MESSAGING_DISABLED_FLAG, false).to_s.downcase)
  end

  ### Instance Methods

  def disabled?
    if sms?
      MessageType.sms_messaging_disabled?
    elsif email?
      MessageType.email_messaging_disabled?
    else
      false
    end
  end

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
