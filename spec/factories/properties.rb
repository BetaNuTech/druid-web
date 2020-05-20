# == Schema Information
#
# Table name: properties
#
#  id                   :uuid             not null, primary key
#  name                 :string
#  address1             :string
#  address2             :string
#  address3             :string
#  city                 :string
#  state                :string
#  zip                  :string
#  country              :string
#  organization         :string
#  contact_name         :string
#  phone                :string
#  fax                  :string
#  email                :string
#  units                :integer
#  notes                :text
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  active               :boolean          default("true")
#  website              :string
#  school_district      :string
#  amenities            :text
#  application_url      :string
#  team_id              :uuid
#  call_lead_generation :boolean          default("true")
#

FactoryBot.define do
  factory :property do
    sequence :name do |n|
      n.to_s
    end
    address1 { Faker::Address.street_address }
    address2 { Faker::Address.secondary_address }
    address3 { Faker::Address.building_number }
    city { Faker::Address.city }
    state { Faker::Address.state }
    zip { Faker::Address.postcode }
    country { "USA" }
    organization { Faker::Company.name }
    contact_name { Faker::Name.name }
    phone { Faker::PhoneNumber.phone_number }
    fax { Faker::PhoneNumber.phone_number }
    email { Faker::Internet.email }
    # TODO: this is causing error
    #units { Faker::Number.number(3) }
    notes { Faker::Lorem.sentence }
    website { Faker::Internet.url }
    school_district { Faker::Company.name }
    amenities { Array.new(rand(10)){Faker::Lorem.word}.join(',') }
    application_url { Faker::Internet.url }
    team
    active { true }
    after(:create) do |property|
      PropertyUser.create(user: create(:user), property: property, role: 'agent')
    end
  end
end
