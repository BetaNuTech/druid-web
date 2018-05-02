FactoryBot.define do
  factory :message_delivery_adapter do
    message_type { create(:message_type) }
    sequence :slug do |n|
      "Name#{n}"
    end
    name { Faker::Lorem.sentence }
    description { Faker::Lorem.sentence }
    active { true }
  end
end
