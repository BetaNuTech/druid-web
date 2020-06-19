FactoryBot.define do
  factory :roommate do
    lead { create(:lead) }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    phone { Faker::PhoneNumber.phone_number }
    email { Faker::Internet.email }
    notes { Faker::Lorem.sentence }
    relationship { 'other' }

    factory :guarantor_roommate do
      occupancy { 'guarantor' }
      relationship { 'other' }
    end

    factory :child_roommate do
      occupancy { 'child' }
      relationship { 'dependent' }
    end

  end
end
