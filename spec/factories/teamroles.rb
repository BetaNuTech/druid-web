# == Schema Information
#
# Table name: teamroles
#
#  id          :uuid             not null, primary key
#  name        :string
#  slug        :string
#  description :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

FactoryBot.define do
  factory :teamrole do
    name { Faker::Lorem.word }
    sequence :slug do |n|
      "TeamRole#{n}"
    end
    description { Faker::Lorem.sentence }

    factory :manager_teamrole do
      name "Manager"
      slug "manager"
      description "Property Manager"
    end

    factory :lead_teamrole do
      name "Lead"
      slug "lead"
      description "Team Lead"
    end

    factory :agent_teamrole do
      name "Agent"
      slug "agent"
      description "Agent"
    end

    factory :none_teamrole do
      name "None"
      slug "none"
      description "No Role Assigned"
    end
  end
end
