FactoryBot.define do
  factory :scheduled_action do
    user
    target { create(:lead, user: user) }
    description { Faker::Lorem.sentence }
    schedule
  end
end
