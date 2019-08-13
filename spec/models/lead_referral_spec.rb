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

require 'rails_helper'

RSpec.describe LeadReferral, type: :model do
  let(:lead) { create(:lead) }

  it "can be initialized" do
    referral = build(:lead_referral)
  end

  it "can be saved" do
    referral = build(:lead_referral)
    referral.lead = lead
    assert referral.save
  end

  describe "validations" do

    it "should not require a referrable" do
      referral = build(:lead_referral, lead: lead, referrable: nil)
      assert referral.save
    end

    it "should not require a lead_referral_source" do
      referral = build(:lead_referral,lead: lead, lead_referral_source: nil)
      assert referral.save
    end

    it "should require either a note or lead_referral_source" do
      referral = build(:lead_referral, lead: lead, lead_referral_source: nil, note: nil)
      refute referral.valid?
      referral.lead_referral_source = create(:lead_referral_source)
      assert referral.valid?
      referral.lead_referral_source = nil
      referral.note = 'Foo'
      assert referral.valid?
    end

  end

end
