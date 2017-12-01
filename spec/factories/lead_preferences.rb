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
    min_area 1
    max_area 1
    min_price "9.99"
    max_price "9.99"
    move_in "2017-12-01 10:42:48"
    baths "9.99"
    pets false
    smoker false
    washerdryer false
    notes "MyText"
  end
end
