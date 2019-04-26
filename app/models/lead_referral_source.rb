# == Schema Information
#
# Table name: lead_referral_sources
#
#  id         :uuid             not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class LeadReferralSource < ApplicationRecord
  ### Class Concerns/Extensions
  include Seeds::Seedable
  audited

  ### Constants
  ALLOWED_PARAMS = [:name]

  ### Validations
  validates :name, presence: true
end
