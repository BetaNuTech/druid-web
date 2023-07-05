# == Schema Information
#
# Table name: referral_bounces
#
#  id           :uuid             not null, primary key
#  property_id  :uuid             not null
#  propertycode :string           not null
#  campaignid   :string           not null
#  trackingid   :string
#  referer      :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
FactoryBot.define do
  factory :referral_bounce do
    association :property
    propertycode { Faker::Lorem.word }
    campaignid { Faker::Lorem.word }
    trackingid { Faker::Lorem.word }
    referer { Faker::Internet.url }
    created_at { Faker::Time.between(from: DateTime.now - 1, to: DateTime.now) }
    updated_at { Faker::Time.between(from: DateTime.now - 1, to: DateTime.now) }
  end
end
