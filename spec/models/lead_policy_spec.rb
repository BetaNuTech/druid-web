require 'rails_helper'

RSpec.describe LeadPolicy do
  include_context "users"

  describe "policy" do
    describe "allowed params for a new Lead" do
      let(:admin_lead_params) { 
        Lead::ALLOWED_PARAMS + [{preference_attributes: LeadPreference::ALLOWED_PARAMS }]
      }
      let(:agent_lead_params) { 
        Lead::ALLOWED_PARAMS + [{preference_attributes: LeadPreference::ALLOWED_PARAMS - [:optout_email, :optin_sms] }]
      }

      describe "for administrators" do
        it "should allow all params" do
          policy = LeadPolicy.new(administrator, Lead)
          expect(policy.allowed_params).to eq(admin_lead_params)
        end
      end

      describe "for corporate users" do
        it "should allow all params" do
          policy = LeadPolicy.new(corporate, Lead)
          expect(policy.allowed_params).to eq(admin_lead_params)
        end
      end

      describe "for managers" do
        it "should allow all params" do
          policy = LeadPolicy.new(manager, Lead)
          expect(policy.allowed_params).to eq(agent_lead_params)
        end
      end

      describe "for agents" do
        it "should allow all params" do
          policy = LeadPolicy.new(manager, Lead)
          expect(policy.allowed_params).to eq(agent_lead_params)
        end
      end
    end
  end
end
