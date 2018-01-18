# == Schema Information
#
# Table name: property_agents
#
#  id          :uuid             not null, primary key
#  user_id     :uuid
#  property_id :uuid
#  active      :boolean          default(TRUE)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

FactoryBot.define do
  factory :property_agent do
    user { create(:user) }
    property { create(:property) }
    active true
  end
end
