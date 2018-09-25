FactoryBot.define do
  factory :lead_transition do
    lead
    last_state 'open'
    current_state 'prospect'
    classification 'lead'
    memo { Faker::Lorem.sentence}
  end
end
