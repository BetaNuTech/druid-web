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

  # Leads at inactive properties (sold or no longer managed) are most of the
  # table; lists, searches and queues should show only properties still operated.
  describe "Scope" do
    let(:active_property) { create(:property, active: true) }
    let(:inactive_property) { create(:property, active: false) }
    let!(:active_lead) { create(:lead, property: active_property) }
    let!(:inactive_lead) { create(:lead, property: inactive_property) }
    let!(:unassigned_lead) { create(:lead, property: nil) }

    def resolve(user)
      LeadPolicy::Scope.new(user, Lead.where(id: [active_lead.id, inactive_lead.id, unassigned_lead.id])).resolve
    end

    context "for administrators" do
      it "shows leads at active properties and leads with no property yet" do
        expect(resolve(administrator)).to contain_exactly(active_lead, unassigned_lead)
      end

      it "still opens a lead at an inactive property directly" do
        expect(LeadPolicy.new(administrator, inactive_lead).show?).to be true
      end
    end

    context "for corporate users" do
      it "shows only leads at active properties" do
        expect(resolve(corporate)).to contain_exactly(active_lead)
      end
    end

    # Callers use the resolved scope as an id subquery. With includes + a
    # condition on properties, Rails eager-loads and ignores .select, and
    # Postgres rejects the subquery ("subquery has too many columns") -- this
    # broke the property duplicates page for corporate users.
    it "stays usable as an id subquery for administrators and corporate users" do
      [administrator, corporate].each do |user|
        expect(LeadPolicy::Scope.new(user, Lead).resolve.select(:id).to_sql).to match(/\ASELECT "leads"."id" FROM/)
        expect { DuplicateLead.for_property_accessible_by_user(active_property, user).to_a }.not_to raise_error
      end
    end
  end
end
