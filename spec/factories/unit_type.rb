FactoryBot.define do
  factory :unit_type do
    name { Faker::Lorem.word }
    active true
  end
end
