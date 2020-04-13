# == Schema Information
#
# Table name: engagement_policy_actions
#
#  id                     :uuid             not null, primary key
#  engagement_policy_id   :uuid
#  lead_action_id         :uuid
#  description            :text
#  deadline               :decimal(, )
#  retry_count            :integer          default("0")
#  retry_delay            :decimal(, )      default("0.0")
#  retry_delay_multiplier :string           default("none")
#  score                  :decimal(, )      default("1.0")
#  active                 :boolean          default("true")
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

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

  describe "validations" do
    let(:epa) { create(:engagement_policy_action) }

    it "should have a description" do
      assert(epa.valid?)
      epa.description = nil
      refute(epa.valid?)
    end

    it "should have a deadline greater than 0" do
      assert(epa.valid?)
      epa.deadline = nil
      refute(epa.valid?)
      epa.deadline = 0
      refute(epa.valid?)
    end

    it "should have a retry_count 0 or greater" do
      assert(epa.valid?)
      epa.retry_count = nil
      refute(epa.valid?)
      epa.retry_count = 0
      assert(epa.valid?)
    end

    it "should have a retry_delay 0 or greater" do
      assert(epa.valid?)
      epa.retry_delay = nil
      refute(epa.valid?)
      epa.retry_delay = 0
      assert(epa.valid?)
    end

    it "should have a score greater than 0" do
      assert(epa.valid?)
      epa.score = nil
      refute(epa.valid?)
      epa.score = 0
      refute(epa.valid?)
    end

    it "should have a retry_delay_multiplier" do
      assert(epa.valid?)
      epa.retry_delay_multiplier = nil
      refute(epa.valid?)
      epa.retry_delay_multiplier = 'foobar'
      refute(epa.valid?)
      epa.retry_delay_multiplier = EngagementPolicyAction::VALID_DELAY_MULTIPLIERS.last
      assert(epa.valid?)
    end


  end
end
