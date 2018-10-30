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
    sequence :name do |n|
      n.to_s
    end
    description { Faker::GameOfThrones.quote }
  end
end
