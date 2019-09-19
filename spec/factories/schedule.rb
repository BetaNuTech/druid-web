FactoryBot.define do
  factory :schedule do
    date { Faker::Date.forward(days: 30) }
    time { Faker::Time.forward(days: 30) }
    rule { 'singular' }
    duration { 30 }
  end
end
