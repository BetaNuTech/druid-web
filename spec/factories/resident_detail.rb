FactoryBot.define do
  factory :resident_detail do
    resident { create(:resident) }
    phone1 { Faker::PhoneNumber.phone_number }
    phone1_type { 'Work' }
    phone1_tod { 'Day' }
    phone2 { Faker::PhoneNumber.phone_number }
    phone2_type { 'Cell' }
    phone2_tod { 'Night' }
    email { Faker::Internet.email }
    ssn { Faker::Number.number(digits: 9) }
    id_number { Faker::Number.number(digits: 10) }
    id_state { Faker::Address.state_abbr }
  end
end
