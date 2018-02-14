FactoryBot.define do
  factory :lead_action do
    name { Faker::Lorem.word }
    description { Faker::Lorem.sentence }
    active true
  end
end
