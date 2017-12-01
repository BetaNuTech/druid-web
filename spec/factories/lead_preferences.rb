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

FactoryBot.define do
  factory :lead_preference do
    min_area 1000
    max_area 2000
    min_price 500.0
    max_price 2000.0
    move_in "2017-12-01 10:42:48"
    baths 1.5
    pets true
    smoker false
    washerdryer false
    notes "Lead notes"
  end
end
