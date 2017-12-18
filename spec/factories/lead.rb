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
#

FactoryBot.define do
  factory :lead do
    title { Faker::Name.prefix }
    first_name { Faker::Name.first_name }
    last_name{ Faker::Name.last_name }
    referral 'Newspaper'
    state 'active'
    notes { Faker::Lorem.sentence }
    first_comm { DateTime.now }
    last_comm { DateTime.now }
    preference_attributes { FactoryBot.attributes_for(:lead_preference)}
  end
end
