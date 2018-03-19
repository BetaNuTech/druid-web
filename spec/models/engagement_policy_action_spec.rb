require 'rails_helper'

RSpec.describe EngagementPolicyAction, type: :model do
  it "can be initialized" do
    epa = build(:engagement_policy_action)
  end

  it "can be saved" do
    epa = build(:engagement_policy_action)
    assert(epa.save)
  end

  it "can be updated" do
    epa = build(:engagement_policy_action)
    expect {
      epa.description = 'new description'
      epa.save!
      epa.reload
    }.to change{ epa.description }
  end

  describe "associations" do
    let(:epa) { create(:engagement_policy_action) }

    it "should have an engagement_policy" do
      assert(epa.engagement_policy.present?)
    end

    it "should have a lead_action" do
      assert(epa.lead_action.present?)
    end
  end
end
