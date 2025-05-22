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
  WHITELIST_VIOLATION_MESSAGE='Message recipient is not in whitelist'
  FORBIDDEN_RECIPIENT_MESSAGE='Message recipient does not want this message type'
  WHITELIST_FLAG = 'MESSAGE_WHITELIST_ENABLED'
  MESSAGE_TYPE_DISABLED_MESSAGE="Delivery for this Message Type is disabled by a system flag ('#{MessageType::SMS_MESSAGING_DISABLED_FLAG}' or '#{MessageType::EMAIL_MESSAGING_DISABLED_FLAG}')"
  PROVIDER_ERRORS = ['Net::SMTPAuthenticationError', 'Net::SMTPSyntaxError', 'Net::SMTPUnknownError']

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
    return false unless id.present?
    unless deliverable?
      refuse_delivery(deliverability[:message])
      return false
    end
    Messages::Sender.new(self).deliver
    reload
    message.handle_message_delivery(self) if delivered?
    return delivered?
  end

  def delivered?
    return delivered_at.present?
  end

  def success?
    return status == SUCCESS
  end

  def deliverable?
    deliverability[:deliver]
  end

  def set_attempt
    self.attempt ||= MessageDelivery.previous_attempt_number(message) + 1
    self.attempted_at ||= DateTime.current
    return true
  end

  def deliverability
    @deliverability ||=
      if message_type_disabled?
        {deliver: false, message: MESSAGE_TYPE_DISABLED_MESSAGE}
      elsif violates_whitelist?
        {deliver: false, message: WHITELIST_VIOLATION_MESSAGE}
      elsif forbidden_by_recipient?
        {deliver: false, message: FORBIDDEN_RECIPIENT_MESSAGE}
      elsif has_previous_delivery?
        {deliver: false, message: ALREADY_SENT_MESSAGE}
      else
        {deliver: true, message: nil}
      end
  end


  def has_previous_delivery?
    return message.deliveries.successful.exists?
  end

  def violates_whitelist?
    enforce_whitelist? &&
      !message_recipient_whitelist.include?(message.to_address)
  end

  def enforce_whitelist?
    %w{1 true t yes y}.include?(ENV.fetch(WHITELIST_FLAG, false).to_s.downcase)
  end

  def message_type_disabled?
    message&.message_type&.disabled?
  end

  def forbidden_by_recipient?
    return false if message.for_compliance?
    case message.message_type
    when MessageType.sms
      message&.messageable&.optout_sms?
    when MessageType.email
      message&.messageable&.optout_email?
    else
      false
    end
  end

  private

  def refuse_delivery(log_message)
    self.attempted_at = DateTime.current
    self.status = FAILED
    self.log = log_message
    self.save

    message.reload
    if log_message != ALREADY_SENT_MESSAGE && message.state != 'sent'
      message.fail! unless message.failed?
    end
  end

  def email_whitelist
    return User.select('distinct email').
      map(&:email).
      select{|p| p.present?}
  end

  def phone_whitelist
    return UserProfile.select(:cell_phone, :office_phone, :fax).
      map{|p| [p.cell_phone, p.office_phone, p.fax]}.
      flatten.compact.select{|p| p.present?}.
      map{|p| Message.format_phone(p)}.
      uniq
  end

  def message_recipient_whitelist
    return (email_whitelist + phone_whitelist)
  end

end
