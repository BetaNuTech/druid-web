# == Schema Information
#
# Table name: lead_referrals
#
#  id                      :uuid             not null, primary key
#  lead_id                 :uuid             not null
#  lead_referral_source_id :uuid
#  referrable_id           :uuid
#  referrable_type         :string
#  note                    :text
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#

class LeadReferral < ApplicationRecord
  ### Class Concerns/Extensions
  audited

  ### Constants
  ALLOWED_PARAMS = [:id, :note, :lead_referral_source_id, :referrable_id, :referrable_type, :_destroy]

  ### Attributes

  ### Enums

  ### Associations
  belongs_to :lead
  belongs_to :lead_referral_source, optional: true
  belongs_to :referrable, polymorphic: true, optional: true

  ### Scopes

  ### Validations
  validates_associated :referrable
  validates :note, presence: true, if: -> { lead_referral_source_id.nil? }

  ### Callbacks

  ### Class Methods

  ### Instance Methods

  private

end
