# == Schema Information
#
# Table name: property_listings
#
#  id          :uuid             not null, primary key
#  code        :string
#  description :string
#  property_id :uuid
#  source_id   :uuid
#  active      :boolean          default(TRUE)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

FactoryBot.define do
  factory :property_listing do
    code { rand.to_s }
    description { "This is a property listing." }
    property { create(:property) }
    source { create(:lead_source) }
    active { true }
  end
end
