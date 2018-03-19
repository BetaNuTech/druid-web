# == Schema Information
#
# Table name: engagement_policies
#
#  id          :uuid             not null, primary key
#  property_id :uuid
#  lead_state  :string
#  description :text
#  version     :integer          default(0)
#  active      :boolean          default(TRUE)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

FactoryBot.define do
  factory :engagement_policy do
    property { create(:property) }
    lead_state { "prospect" }
    description { Faker::Lorem.sentence }
    version { 0 }
    active { true }
  end
end
