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

    factory :agent do
      name 'agent'
      slug 'agent'
      description 'agent role'
    end
  end
end
