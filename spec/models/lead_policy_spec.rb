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

    describe "invalidate?" do
      let(:property) { create(:property) }
      let(:regular_lead) { create(:lead, property: property, state: 'prospect') }
      let(:invalidated_lead) { create(:lead, property: property, state: 'invalidated', classification: 'duplicate') }
      let(:system_user) { User.system }
      let(:system_lead) { create(:lead, property: property, state: 'prospect', user: system_user) }

      context "for administrators" do
        it "allows invalidation of regular leads" do
          policy = LeadPolicy.new(administrator, regular_lead)
          expect(policy.invalidate?).to be true
        end

        it "allows invalidation of system user leads" do
          policy = LeadPolicy.new(administrator, system_lead)
          expect(policy.invalidate?).to be true
        end

        it "does not allow invalidation of already invalidated leads" do
          policy = LeadPolicy.new(administrator, invalidated_lead)
          expect(policy.invalidate?).to be false
        end
      end

      context "for managers" do
        it "allows invalidation of regular leads in their property" do
          # Assign manager to property
          property.assign_user(user: manager, role: 'manager')

          policy = LeadPolicy.new(manager, regular_lead)
          expect(policy.invalidate?).to be true
        end

        it "allows invalidation of system user leads in their property" do
          # Assign manager to property
          property.assign_user(user: manager, role: 'manager')

          policy = LeadPolicy.new(manager, system_lead)
          expect(policy.invalidate?).to be true
        end

        it "does not allow invalidation of regular leads in other properties" do
          other_property = create(:property)
          other_lead = create(:lead, property: other_property, state: 'prospect')

          policy = LeadPolicy.new(manager, other_lead)
          expect(policy.invalidate?).to be_falsey
        end
      end

      context "for agents" do
        it "allows invalidation of their own regular leads" do
          # Assign agent to property and set as lead owner
          property.assign_user(user: agent, role: 'agent')
          regular_lead.update!(user: agent)

          policy = LeadPolicy.new(agent, regular_lead)
          expect(policy.invalidate?).to be true
        end

        it "allows invalidation of system user leads (for Lea handoff processing)" do
          # Assign agent to property
          property.assign_user(user: agent, role: 'agent')

          policy = LeadPolicy.new(agent, system_lead)
          expect(policy.invalidate?).to be true
        end

        it "allows invalidation of leads in same property (even if owned by others)" do
          other_agent = create(:user)
          property.assign_user(user: agent, role: 'agent')
          property.assign_user(user: other_agent, role: 'agent')

          # Create a NEW lead owned by other agent in same property
          other_agent_lead = create(:lead, property: property, state: 'prospect', user: other_agent)

          policy = LeadPolicy.new(agent, other_agent_lead)
          # Agents can invalidate leads in their property (same_property? returns true)
          expect(policy.invalidate?).to be true
        end
      end
    end
  end
end
