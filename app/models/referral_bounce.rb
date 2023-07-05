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
class ReferralBounce < ApplicationRecord
  belongs_to :property
  validates :propertycode, :referer, presence: true
end
