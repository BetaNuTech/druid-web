FactoryBot.define do
  factory :phone_number do
    name { Faker::Lorem.word }
    number {Faker::PhoneNumber.phone_number }
    prefix { 1 }
  end
end
