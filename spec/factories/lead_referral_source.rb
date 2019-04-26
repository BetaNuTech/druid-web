FactoryBot.define do
  factory :lead_referral_source do
    name { Faker::Lorem.sentence + rand(10000).to_s}
  end
end
