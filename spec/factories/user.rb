FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { 'Foobar123' }
    password_confirmation { 'Foobar123' }
    timezone { 'America/Detroit' } 
    profile { create(:user_profile)}
  end
end
