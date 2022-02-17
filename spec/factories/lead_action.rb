FactoryBot.define do
  factory :lead_action do
    sequence :name do |n|
      Faker::Lorem.word + n.to_s
    end
    description { Faker::Lorem.sentence }
    is_contact { false }
    active { true }
  end
end
