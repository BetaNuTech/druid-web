FactoryBot.define do
  factory :message_template do
    message_type { create(:message_type)}
    name { Faker::Lorem.sentence }
    subject { Faker::Lorem.sentence }
    body { Faker::Lorem.paragraph }
  end
end
