# == Schema Information
#
# Table name: message_deliveries
#
#  id              :uuid             not null, primary key
#  message_id      :uuid
#  message_type_id :uuid
#  attempt         :integer
#  attempted_at    :datetime
#  status          :string
#  log             :text
#  delivered_at    :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class MessageDelivery < ApplicationRecord
  ### Class Concerns/Extensions

  ### Constants
  SUCCESS='OK'
  FAILED='FAILED'
  ALREADY_SENT_MESSAGE='Message already sent successfully'

  ### Associations
  belongs_to :message
  belongs_to :message_type

  ### Validations
  validates :attempt, :attempted_at, presence: true

  ### Scopes
  scope :successful, -> { where(status: SUCCESS) }
  scope :failed, -> { where(status: FAILED) }

  ### Callbacks
  before_validation :set_attempt, on: :create

  ### Class Methods

  def self.previous(message)
    return where(message_id: message.id).order("attempt DESC").first
  end

  def self.previous_attempt_number(message)
    return previous(message).try(:attempt) || 0
  end

  def self.next(message)
    return MessageDelivery.new(
      message: message,
      message_type: message.message_type
    )
  end

  ### Instance Methods

  def perform
    if message.deliveries.successful.exists?
      refuse_delivery(ALREADY_SENT_MESSAGE)
      return false
    else
      sender = Messages::Sender.new(self)
      sender.deliver
      reload
      return delivered?
    end
  end


  def delivered?
    return delivered_at.present?
  end

  def success?
    return status == SUCCESS
  end

  def set_attempt
    self.attempt ||= MessageDelivery.previous_attempt_number(message) + 1
    self.attempted_at ||= DateTime.now
    return true
  end

  private

  def refuse_delivery(log_message)
    self.attempted_at = DateTime.now
    self.status = FAILED
    self.log = log_message
    self.save
  end

end
