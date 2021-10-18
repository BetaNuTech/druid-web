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
#  model          :boolean          default(FALSE)
#

FactoryBot.define do
  factory :unit do
    property { create(:property) }
    unit_type { create(:unit_type) }
    rental_type { create(:rental_type) }
    unit { Faker::Number.between(from: 1, to: 10000) + Time.now.to_i }
    floor { Faker::Number.between(from: 1, to: 3) }
    sqft { Faker::Number.between(from: 400, to: 1200) }
    bedrooms { Faker::Number.between(from: 1, to: 3) }
    bathrooms { Faker::Number.between(from: 1, to: 3) }
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
    occupancy { 'vacant' }
    lease_status { 'available'}
    market_rent { Faker::Number.between(from: 600, to: 2500) }
  end
end
