FactoryBot.define do
  factory :schedule do
    date { Faker::Date.forward(30) }
    time { Faker::Time.forward(30) }
    rule { 'singular' }
    duration { 30 }
  end
end
