# == Schema Information
#
# Table name: lead_preferences
#
#  id          :uuid             not null, primary key
#  lead_id     :uuid
#  min_area    :integer
#  max_area    :integer
#  min_price   :decimal(, )
#  max_price   :decimal(, )
#  move_in     :datetime
#  baths       :decimal(, )
#  pets        :boolean
#  smoker      :boolean
#  washerdryer :boolean
#  notes       :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class LeadPreference < ApplicationRecord
  DEFAULT_UNIT_SYSTEM = :imperial
  belongs_to :lead

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

  def unit_system
    DEFAULT_UNIT_SYSTEM
  end

end
