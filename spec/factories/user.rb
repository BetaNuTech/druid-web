FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password 'Foobar123'
    password_confirmation 'Foobar123'
  end
end
