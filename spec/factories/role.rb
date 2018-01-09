FactoryBot.define do
  factory :role do

    name { Faker::Lorem.word }
    slug  { Faker::Lorem.word }
    description { Faker::Lorem.sentence }

    factory :administrator_role do
      name 'administrator'
      slug 'administrator'
      description 'admin role'
    end

    factory :operator_role do
      name 'operator'
      slug 'operator'
      description 'operator role'
    end

    factory :agent_role do
      name 'agent'
      slug 'agent'
      description 'agent role'
    end

    factory :other_role do
      name 'other'
      slug 'other'
      description 'other role'
    end
  end
end
