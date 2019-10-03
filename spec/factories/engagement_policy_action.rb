FactoryBot.define do
  factory :engagement_policy_action do
    engagement_policy
    lead_action
    description { Faker::Lorem.sentence }
    deadline { Faker::Number.between(from: 1, to: 120) }
    retry_count { Faker::Number.between(from: 1, to: 5) }
    retry_delay { Faker::Number.between(from: 1, to: 120) }
    retry_delay_multiplier { 'none' }
    score { 1.0 }
    active { true }
  end
end
