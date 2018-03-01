FactoryBot.define do
  factory :resident do
    status { "current" }
    dob { Faker::Date.birthday(18,99) }
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
      property = create(:property)
      resident.property = property
      resident.unit = create(:unit, property_id: property.id)
      resident.lead = create(:lead, property_id: property.id)
    end

  end
end
