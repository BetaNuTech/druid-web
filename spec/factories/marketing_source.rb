FactoryBot.define do
  factory :marketing_source do
    active { true }
    property { create(:property) }
    name { Faker::Lorem.sentence }
    description { Faker::Lorem.sentence }
    tracking_code { Faker::Internet.email }
    tracking_email { Faker::Internet.email }
    tracking_number { Faker::PhoneNumber.phone_number }
    destination_number { Faker::PhoneNumber.phone_number }
    fee_type { MarketingSource.fee_types.keys[rand(6)] }
    fee_rate { Faker::Number.decimal(l_digits: 2) }
    start_date { DateTime.now }
  end
end
