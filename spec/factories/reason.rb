FactoryBot.define do
  factory :reason do
    sequence :name do |n|
      "Reason #{n}"
    end
    description { Faker::Lorem.sentence }
    active true
  end
end
