FactoryBot.define do
  factory :message_delivery_adapter do
    message_type { create(:message_type) }
    sequence :slug do |n|
      "Name#{n}"
    end
    name { Faker::Lorem.sentence }
    description { Faker::Lorem.sentence }
    active { true }

    factory :email_delivery_adapter do
      message_type { MessageType.email || create(:email_message_type)}
      name 'ActionMailer'
      slug 'ActionMailer'
      active { true }
    end
  end
end
