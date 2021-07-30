FactoryBot.define do
  factory :resident do
    status { "current" }
    sequence :residentid do |n|
      "residentid-#{n}-#{rand(10000)}"
    end
    dob { Faker::Date.birthday(min_age: 18, max_age: 99) }
    title { Faker::Name.prefix }
    first_name { Faker::Name.first_name }
    middle_name { Faker::Name.first_name }
    last_name{ Faker::Name.last_name }
    address1 { Faker::Address.street_address }
    address2 { Faker::Address.secondary_address }
    city { Faker::Address.city }
    state { Faker::Address.state }
    zip { Faker::Address.postcode }
    country { "USA" }

    after(:build) do |resident|
      unless resident.property.present?
        property = create(:property)
        resident.property_id = property.id
      end
      resident.unit ||= create(:unit, property_id: resident.property_id)
      #resident.lead ||= create(:lead, property_id: resident.property_id)
      #resident.detail = create(:resident_detail, resident: resident)
    end

  end
end
