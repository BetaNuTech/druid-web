# == Schema Information
#
# Table name: lead_sources
#
#  id         :uuid             not null, primary key
#  name       :string
#  incoming   :boolean
#  slug       :string
#  active     :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  api_token  :string
#

FactoryBot.define do
  factory :lead_source do
    name { Faker::Company.name }
    incoming true
    slug { ['Druid', 'Zillow'][rand(1)] }
    active true

    factory :druid_source do
      name 'Druid WebApp'
      incoming true
      slug 'Druid'
      active 'true'
    end

    factory :zillow_source do
      name 'Zillow'
      incoming true
      slug 'Zillow'
      active true
    end

    factory :yardi_voyager_source do
      name 'YardiVoyager'
      incoming true
      slug 'YardiVoyager'
      active true
    end
  end
end
