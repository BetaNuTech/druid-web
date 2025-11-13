FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { 'Foobar123' }
    password_confirmation { 'Foobar123' }
    timezone { 'America/Detroit' }
    profile { create(:user_profile)}

    factory :system_user do
      email { 'system@bluesky.internal' }
      system_user { true }
      confirmed_at { Time.current }

      after(:build) do |user|
        user.profile = build(:user_profile, first_name: 'Bluesky', last_name: nil)
      end
    end
  end
end
