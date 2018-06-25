# == Schema Information
#
# Table name: unit_types
#
#  id          :uuid             not null, primary key
#  name        :string
#  active      :boolean          default(TRUE)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  description :text
#  property_id :uuid
#  remoteid    :string
#  bathrooms   :integer
#  bedrooms    :integer
#  market_rent :decimal(, )      default(0.0)
#

FactoryBot.define do
  factory :unit_type do
    name { Faker::Lorem.word }
    description { Faker::Lorem.sentence }
    property_id { create(:property).id }
    market_rent { Faker::Number.between(600, 2500) }
    sequence :remoteid do |n|
      "remote-#{n}"
    end
    bedrooms { Faker::Number.between(1,3) }
    bathrooms { Faker::Number.between(1,3) }
    active true
  end
end
