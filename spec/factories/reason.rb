FactoryBot.define do
  factory :reason do
    name { Faker::Lorem.word }
    description { Faker::Lorem.sentence }
    active true
  end
end
