# == Schema Information
#
# Table name: units
#
#  id             :uuid             not null, primary key
#  property_id    :uuid
#  unit_type_id   :uuid
#  rental_type_id :uuid
#  unit           :string
#  floor          :integer
#  sqft           :integer
#  bedrooms       :integer
#  description    :text
#  address1       :string
#  address2       :string
#  city           :string
#  state          :string
#  zip            :string
#  country        :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  remoteid       :string
#  bathrooms      :integer
#  occupancy      :string           default("vacant")
#  lease_status   :string           default("available")
#  available_on   :date
#  market_rent    :decimal(, )      default(0.0)
#

FactoryBot.define do
  factory :unit do
    property { create(:property) }
    unit_type { create(:unit_type) }
    rental_type { create(:rental_type) }
    unit { Faker::Number.between(1, 1000) }
    floor { Faker::Number.between(1,3) }
    sqft { Faker::Number.between(400, 1200) }
    bedrooms { Faker::Number.between(1,3) }
    bathrooms { Faker::Number.between(1,3) }
    description { Faker::Lorem.sentence }
    address1 { Faker::Address.street_address }
    address2 { Faker::Address.secondary_address }
    city { Faker::Address.city }
    state { Faker::Address.state }
    zip { Faker::Address.postcode }
    country { "USA" }
    sequence :remoteid do |n|
      "remote-#{n}"
    end
    occupancy {Unit::OCCUPANCY_STATUSES[rand(1)]}
    lease_status {Unit::LEASE_STATUSES[rand(5)]}
    market_rent { Faker::Number.between(600, 2500) }
  end
end
