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

    factory :corporate_role do
      name 'corporate'
      slug 'corporate'
      description 'corporate role'
    end

    factory :manager_role do
      name 'manager'
      slug 'manager'
      description 'corporate role'
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
