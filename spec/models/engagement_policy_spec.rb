# == Schema Information
#
# Table name: engagement_policies
#
#  id          :uuid             not null, primary key
#  property_id :uuid
#  lead_state  :string
#  description :text
#  version     :integer          default(0)
#  active      :boolean          default(TRUE)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'rails_helper'

RSpec.describe EngagementPolicy, type: :model do

  describe "initialization/saving" do
    let(:engagement_policy) { build(:engagement_policy) }

    it "can be initialized" do
      assert(engagement_policy.active)
    end

    it "can be saved" do
      assert(engagement_policy.save)
    end

    it "can be updated" do
      engagement_policy.save!
      expect {
        engagement_policy.description = "Foobar"
        engagement_policy.save!
        engagement_policy.reload
      }.to change{engagement_policy.description}
    end

  end

  describe "validations" do
    let(:property1) {create(:property)}
    let(:property2) {create(:property)}
    let(:engagement_policy) { create(:engagement_policy, version: 1, property: nil) }
    let(:engagement_policy2) { create(:engagement_policy, version: 2, property: nil) }

    it "has a valid lead state" do
      assert(engagement_policy.valid?)
      engagement_policy.lead_state = "invalid lead state"
      refute(engagement_policy.save)
    end

    it "has a description" do
      assert(engagement_policy.valid?)
      engagement_policy.description = nil
      refute(engagement_policy.save)
    end

    it "has a unique version (scope: property)" do
      assert(engagement_policy.valid?)
      assert(engagement_policy2.valid?)

      # Invalid: Nil Property and same version
      engagement_policy2.version = engagement_policy.version
      refute(engagement_policy2.save)
      # Valid: Property and different version
      engagement_policy2.property = property2
      assert(engagement_policy2.save)
      # Invalid: Same Property and same version
      engagement_policy2.property = engagement_policy.property
      engagement_policy2.version = engagement_policy.version
      refute(engagement_policy2.save)
      # Valid: Same Property and different version
      engagement_policy2.property = engagement_policy.property
      engagement_policy2.version = engagement_policy.version + 1
      assert(engagement_policy2.save)
      # Valid: Different property and same version
      engagement_policy2.property = property2
      engagement_policy2.version = engagement_policy.version
      assert(engagement_policy2.save)
    end
  end

  describe "callbacks" do
    let(:property) { create(:property) }
    let(:property2) { create(:property) }
    let(:engagement_policy) { create(:engagement_policy, version: 1, property: nil) }
    let(:engagement_policy2) { create(:engagement_policy, version: 2, property: nil) }
    let(:engagement_policy3) { create(:engagement_policy, version: 1, property: property) }

    describe "versions" do
      before do
        engagement_policy; engagement_policy2; engagement_policy3
      end

      it "assigns the next version for the nil property before save" do
        ep = create(:engagement_policy, property: nil)
        expect(ep.version).to eq(engagement_policy2.version + 1)
      end

      it "assigns the next version for a property before save" do
        ep = create(:engagement_policy, property: property)
        expect(ep.version).to eq(engagement_policy3.version + 1)
      end

      it "assigns version 1 if no EngagementPolicies are present for the property" do
        ep = create(:engagement_policy, property: property2)
        expect(ep.version).to eq(1)
      end

    end


  end


end
