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
    first_name { Faker::Name.first_name }
    last_name{ Faker::Name.last_name }
    referral {%w{newspaper walk-in call friend}[rand(4)]}
    state { ::Lead.aasm.states.map(&:name)[rand(::Lead.aasm.states.count - 1)] }
    notes { Faker::Lorem.sentence }
    first_comm { DateTime.now }
    last_comm { DateTime.now }
    phone1 { Faker::PhoneNumber.phone_number }
    phone1_type { 'Work' }
    phone1_tod { 'Day' }
    phone2 { Faker::PhoneNumber.phone_number }
    phone2_type { 'Cell' }
    phone2_tod { 'Night' }
    id_number { Faker::Number.number(10) }
    id_state { Faker::Address.state_abbr }
    dob { Faker::Date.birthday(18,99) }
    fax { Faker::PhoneNumber.phone_number }
    email { Faker::Internet.email }
    preference_attributes { FactoryBot.attributes_for(:lead_preference)}
    priority { ["low", "medium", "high", "urgent"][rand(4)] }
    #property { create(:property)}
  end
end
