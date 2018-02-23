FactoryBot.define do
  factory :unit_type do
    name { Faker::Lorem.word }
    description { Faker::Lorem.sentence }
    property_id { create(:property).id }
    active true
  end
end
