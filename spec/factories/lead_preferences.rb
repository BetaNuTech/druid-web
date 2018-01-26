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
#  beds        :integer
#  raw_data    :text
#

FactoryBot.define do
  factory :lead_preference do
    min_area 500
    max_area { rand(1000) + 1001 }
    min_price 1001.0
    max_price { rand(1000) + 1002.0}
    move_in { Faker::Date.forward(60) }
    baths { [1, 1.5, 2, 2.5][rand(3) + 1]}
    pets { Faker::Boolean.boolean }
    smoker { Faker::Boolean.boolean }
    washerdryer { Faker::Boolean.boolean }
    notes {Faker::Lorem.paragraph}
  end
end
