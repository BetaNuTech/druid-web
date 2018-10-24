# == Schema Information
#
# Table name: teams
#
#  id          :uuid             not null, primary key
#  name        :string
#  description :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

FactoryBot.define do
  factory :team do
    name { "Team #{Faker::GameOfThrones.house}" }
    description { Faker::GameOfThrones.quote }
  end
end
