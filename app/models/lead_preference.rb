# == Schema Information
#
# Table name: lead_preferences
#
#  id                :uuid             not null, primary key
#  lead_id           :uuid
#  min_area          :integer
#  max_area          :integer
#  min_price         :decimal(, )
#  max_price         :decimal(, )
#  move_in           :datetime
#  baths             :decimal(, )
#  pets              :boolean
#  smoker            :boolean
#  washerdryer       :boolean
#  notes             :text
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  beds              :integer
#  raw_data          :text
#  unit_type_id      :uuid
#  optout_email      :boolean          default(FALSE)
#  optout_email_date :datetime
#  optin_sms         :boolean          default(FALSE)
#  optin_sms_date    :datetime
#

class LeadPreference < ApplicationRecord

  ### Constants
  DEFAULT_UNIT_SYSTEM = :imperial
  ALLOWED_PARAMS = [:baths, :beds, :min_price, :max_price, :min_area, :max_area,
                    :move_in, :pets, :smoker, :washerdryer, :notes, :raw_data,
                    :unit_type_id, :optout_email, :optin_sms]
  PRIVILEGED_PARAMS = [:id, :optout_email, :optin_sms, :raw_data]
  NO_UNIT_PREFERENCE='(no preference)'

  ### Class Concerns/Extensions
  audited

  ### Associations

  belongs_to :lead
  belongs_to :unit_type, optional: true

  ### Validations

  validates :min_area,
    :max_area,
    :min_price,
    :max_price,
    numericality: { greater_than_or_equal_to: 0 },
    allow_blank: true

  validates :min_area,
    numericality: {
    greater_than: 0,
    less_than: ->(pref) { pref.max_area || pref.min_area + 1}
  },
  allow_blank: true

  validates :max_area,
    numericality: {
    greater_than: ->(pref) { pref.min_area || pref.max_area - 1  }
  },
  allow_blank: true

  validates :min_price,
    numericality: {
    greater_than: 0,
    less_than: ->(pref) { pref.max_price || pref.min_price + 1 }
  },
  allow_blank: true

  validates :max_price,
    numericality: {
    greater_than: ->(pref) { pref.min_price || pref.max_price - 1 }
  },
  allow_blank: true

  ### Instance Methods

  def unit_type_name
    unit_type.try(:name) || NO_UNIT_PREFERENCE
  end

  def unit_system
    DEFAULT_UNIT_SYSTEM
  end

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

  def source_document
    data = ( JSON.parse(raw_data) rescue nil ) or return nil
    return {html: data.fetch("html", false), text: data.fetch("plain")}
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
    when 'yes', 'start'
      optin_sms!
    when 'stop'
      optout_sms!
    else
      if optout_sms? && body.match?(/yes|ok|okay|sure|start/i)
        optin_sms!
      end
    end
  end


end
