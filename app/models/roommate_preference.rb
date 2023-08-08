# == Schema Information
#
# Table name: roommate_preferences
#
#  id                :uuid             not null, primary key
#  roommate_id       :bigint
#  optout_email      :boolean          default(FALSE)
#  optout_email_date :datetime
#  optin_sms         :boolean          default(FALSE)
#  optin_sms_date    :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class RoommatePreference < ApplicationRecord
  belongs_to :roommate

  def optout_email!
    self.optout_email = true
    self.optout_email_date ||= DateTime.current
    save
  end

  def optin_email!
    self.optout_email = false
    self.optout_email_date = nil
    save
  end

  def optin_sms!
    unless self.optin_sms
      self.optin_sms = true
      self.optin_sms_date = DateTime.current
      save
      lead.send_sms_optin_confirmation
    end
  end

  def optout_sms!
    self.optin_sms = false
    self.optin_sms_date = DateTime.current
    save
    lead.send_sms_optout_confirmation
  end

  def optout_email?
    optout_email
  end

  def optin_email?
    !optout_email?
  end

  def optin_sms?
    optin_sms
  end

  def optout_sms?
    !optin_sms
  end

  def handle_message_response(message_delivery)
    case message_delivery&.message&.message_type
    when MessageType.sms
      if message_delivery&.message&.incoming?
        handle_sms_reply(message_delivery)
      end
    when MessageType.email
      # NOOP
    else
      # NOOP
    end
  end

  def handle_sms_reply(message_delivery)
    body = message_delivery&.message&.body || ''
    body = body.downcase.strip
    case body
    when 'yes', 'start', 'si', 'ok', 'okay', 'sure'
      optin_sms!
    when 'stop', 'detener'
      optout_sms!
    else
      if optout_sms? && body.match?(/yes|ok|okay|sure|start|si/i)
        optin_sms!
      end
    end
  end
end
