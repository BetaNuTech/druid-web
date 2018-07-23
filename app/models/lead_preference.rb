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
#

class LeadPreference < ApplicationRecord

  ### Constants
  DEFAULT_UNIT_SYSTEM = :imperial
  ALLOWED_PARAMS = [:baths, :beds, :min_price, :max_price, :min_area, :max_area,
                    :move_in, :pets, :smoker, :washerdryer, :notes, :raw_data,
                    :unit_type_id, :optout_email]
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

  def optout!
    self.optout_email = true
    self.optout_email_date ||= DateTime.now
    save
  end

  def optin!
    self.optout_email = false
    self.optout_email_date = nil
    save
  end

  def optout?
    optout_email
  end

end
