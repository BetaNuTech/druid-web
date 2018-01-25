FactoryBot.define do
  factory :user_profile do
    name_prefix { Faker::Name.prefix }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    name_suffix { Faker::Name.suffix }
    slack { Faker::Name.first_name }
    cell_phone { Faker::PhoneNumber.phone_number }
    office_phone { Faker::PhoneNumber.phone_number }
    fax { Faker::PhoneNumber.phone_number }
    notes { Faker::Lorem.paragraph }
  end
end
