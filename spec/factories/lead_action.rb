FactoryBot.define do
  factory :lead_action do
    name { Faker::Lorem.word }
    description { Faker::Lorem.sentence }
    is_contact { false }
    active true
  end
end
