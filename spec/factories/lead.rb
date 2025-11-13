# == Schema Information
#
# Table name: leads
#
#  id             :uuid             not null, primary key
#  user_id        :uuid
#  lead_source_id :uuid
#  title          :string
#  first_name     :string
#  last_name      :string
#  referral       :string
#  state          :string
#  notes          :text
#  first_comm     :datetime
#  last_comm      :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  property_id    :uuid
#  phone1         :string
#  phone2         :string
#  fax            :string
#  email          :string
#

FactoryBot.define do
  factory :lead do
    title { Faker::Name.prefix }
    first_name { Faker::Name.first_name + rand(10000).to_s }
    last_name{ Faker::Name.last_name  + rand(10000).to_s}
    company { Faker::Company.name }
    company_title { Faker::Job.title }
    referral {%w{newspaper walk-in call friend}[rand(4)]}
    state { ::Lead.aasm.states.map(&:name)[rand(::Lead.aasm.states.count - 1)] }
    notes { Faker::Lorem.sentence }
    first_comm { DateTime.current }
    last_comm { DateTime.current }
    phone1 { Faker::PhoneNumber.phone_number  + rand(10000).to_s }
    phone1_type { 'Work' }
    phone1_tod { 'Day' }
    phone2 { Faker::PhoneNumber.phone_number + rand(10000).to_s }
    phone2_type { 'Cell' }
    phone2_tod { 'Night' }
    id_number { Faker::Number.number(digits: 10) }
    id_state { Faker::Address.state_abbr }
    dob { Faker::Date.birthday(min_age: 18, max_age: 99) }
    fax { Faker::PhoneNumber.phone_number }
    email { Faker::Internet.email + rand(10000).to_s }
    preference_attributes { FactoryBot.attributes_for(:lead_preference)}
    priority { ["low", "medium", "high", "urgent"][rand(4)] }
    #property { create(:property)}

    trait :with_system_user do
      association :user, factory: :system_user
    end

    trait :with_lea_conversation_url do
      lea_conversation_url { 'https://lea.example.com/conversation/abc123' }
    end

    trait :lea_handoff do
      with_system_user
      with_lea_conversation_url
      state { 'open' }
    end
  end
end
