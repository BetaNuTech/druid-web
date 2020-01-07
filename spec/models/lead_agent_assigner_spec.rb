require 'rails_helper'

RSpec.describe Leads::AgentAssigner do
  include_context "users"

  let(:property1) { create(:property)}
  let(:property1_manager1) {
    user = create(:user); user.role = manager_role; user.save
    property1.assign_user(user: user, role: 'manager')
    user.reload; user
  }
  let(:property1_agent1) {
    user = create(:user); user.role = property_role; user.save
    property1.assign_user(user: user, role: 'agent')
    user.reload; user
  }
  let(:property1_agent2) {
    user = create(:user); user.role = property_role; user.save
    property1.assign_user(user: user, role: 'agent')
    user.reload; user
  }
  let(:property1_agent3) {
    user = create(:user); user.role = property_role; user.save
    property1.assign_user(user: user, role: 'agent')
    user.reload; user
  }
  let(:lead1a){ create(:lead, property: property1, state: 'open') }
  let(:lead1b){ create(:lead, property: property1, state: 'open') }
  let(:lead1c){ create(:lead, property: property1, state: 'open') }

  let(:property2) { create(:property)}
  let(:property2_manager1) {
    user = create(:user); user.role = manager_role; user.save
    property2.assign_user(user: user, role: 'manager')
    user.reload; user
  }
  let(:property2_agent1) {
    user = create(:user); user.role = property_role; user.save
    property2.assign_user(user: user, role: 'agent')
    user.reload; user
  }
  let(:property2_agent2) {
    user = create(:user); user.role = property_role; user.save
    property2.assign_user(user: user, role: 'agent')
    user.reload; user
  }
  let(:lead2a){ create(:lead, property: property2, state: 'open') }
  let(:lead2b){ create(:lead, property: property2, state: 'open') }
  let(:lead2c){ create(:lead, property: property2, state: 'open') }

  describe "An AgentAssignment instance within the AgentAssigner" do
    it "should return assignable agents" do
      service = Leads::AgentAssigner.new(
        user: property1_manager1,
        property: property1,
        assignments: [
          {agent_id: property1_agent1.id, lead_id: lead1a.id},
          {agent_id: property1_agent2.id, lead_id: lead1b.id},
          {agent_id: property1_agent3.id, lead_id: lead1c.id},
        ]
      )
      assignment = service.assignments.first
      expect(assignment.lead).to eq(lead1a)
      expect(assignment.assignable_agents.sort).to eq(property1.users.sort)
    end
  end

  describe "initialized with an array of leads" do
    it "should initialize an empty collection of assignments" do
      service = Leads::AgentAssigner.new(
        user: property1_manager1,
        property: property1,
        leads: [lead1a, lead1b, lead1c]
      )

      expect(service.assignments.count).to eq(3)
      expect(service.assignments.first.lead).to eq(lead1a)
      expect(service.assignments.first.agent).to eq(nil)
      expect(service.assignments.first.user).to eq(property1_manager1)
    end
  end


  describe "With a missing current user" do
    it "should not be able to assign leads" do
      service = Leads::AgentAssigner.new(
        user: nil,
        property: property1,
        assignments: [
          {agent_id: property1_agent1.id, lead_id: lead1a.id},
          {agent_id: property1_agent2.id, lead_id: lead1b.id},
        ]
      )

      result = service.call
      lead1a.reload; lead1b.reload; lead1c.reload

      refute(result)
      refute(service.valid?)
    end
  end

  describe "An agent" do
    it "should not be able to assign leads" do
      service = Leads::AgentAssigner.new(
        user: property1_agent1,
        property: property1,
        assignments: [
          {agent_id: property1_agent2.id, lead_id: lead1a.id},
          {agent_id: property1_agent3.id, lead_id: lead1b.id},
        ]
      )

      result = service.call
      lead1a.reload; lead1b.reload; lead1c.reload

      refute(result)
      refute(service.valid?)
    end
  end

  describe "A property manager" do
    describe "providing missing/incomplete assignment data" do
      it "will be skipped" do
        service = Leads::AgentAssigner.new(
          user: property1_manager1,
          property: property1,
          assignments: [
            {agent_id: nil, lead_id: lead1a.id},
            {agent_id: property1_agent2.id, lead_id: nil},
            {agent_id: property1_agent3.id, lead_id: lead1c.id},
          ]
        )

        result = service.call
        lead1a.reload; lead1b.reload; lead1c.reload

        assert(result)
        assert(service.valid?)
        expect(service.assignments.count).to eq(1)
      end
    end

    describe "assigning open leads" do
      describe "from their own property" do
        describe "to agents at their property" do
          it "should succeed if property assignments match" do
            service = Leads::AgentAssigner.new(
              user: property1_manager1,
              property: property1,
              assignments: [
                {agent_id: property1_agent1.id, lead_id: lead1a.id},
                {agent_id: property1_agent2.id, lead_id: lead1b.id},
                {agent_id: property1_agent3.id, lead_id: lead1c.id},
              ]
            )

            result = service.call
            lead1a.reload; lead1b.reload; lead1c.reload

            assert(result)
            assert(service.valid?)

            expect(lead1a.user_id).to eq(property1_agent1.id)
            assert(lead1a.prospect?)
            expect(lead1b.user_id).to eq(property1_agent2.id)
            assert(lead1b.prospect?)
            expect(lead1c.user_id).to eq(property1_agent3.id)
            assert(lead1c.prospect?)
          end

          it "should fail and do nothing if at least one lead's property assignments don't match" do
            service = Leads::AgentAssigner.new(
              user: property1_manager1,
              property: property1,
              assignments: [
                {agent_id: property1_agent1.id, lead_id: lead1a.id},
                {agent_id: property1_agent2.id, lead_id: lead1b.id},
                {agent_id: property1_agent3.id, lead_id: lead2a.id},
              ]
            )
            result = service.call
            lead1a.reload; lead1b.reload; lead2a.reload

            refute(result)
            refute(service.valid?)
            expect(service.errors.count).to eq(1)
            expect(service.errors.first[:lead]).to eq(lead2a)
            expect(service.errors.first[:error]).to eq('Agent or Current User Property mismatch with Lead')
            expect(service.assignments.last.errors.first).to eq('Agent or Current User Property mismatch with Lead')

            refute(lead1a.prospect?)
            assert(lead1a.user_id.nil?)
            refute(lead1b.prospect?)
            assert(lead1b.user_id.nil?)
            refute(lead2a.prospect?)
            assert(lead2a.user_id.nil?)
          end
        end

        describe "to agents in another property" do
          it "should fail and do nothing" do
            service = Leads::AgentAssigner.new(
              user: property1_manager1,
              property: property1,
              assignments: [
                {agent_id: property2_agent1.id, lead_id: lead1a.id},
                {agent_id: property2_agent2.id, lead_id: lead1b.id}
              ]
            )

            result = service.call
            lead1a.reload; lead1b.reload

            refute(result)
            refute(service.valid?)
            expect(service.errors.count).to eq(2)
            expect(service.errors.first[:lead]).to eq(lead1a)
            expect(service.errors.first[:error]).to eq('Agent or Current User Property mismatch with Lead')
            expect(service.assignments.last.errors.first).to eq('Agent or Current User Property mismatch with Lead')

            refute(lead1a.prospect?)
            assert(lead1a.user_id.nil?)
            refute(lead1b.prospect?)
            assert(lead1b.user_id.nil?)
          end
        end

      end

      describe "from another property" do
        describe "to agents at their property" do
          it "should fail and do nothing" do
            service = Leads::AgentAssigner.new(
              user: property1_manager1,
              property: property1,
              assignments: [
                {agent_id: property1_agent1.id, lead_id: lead2a.id},
                {agent_id: property1_agent2.id, lead_id: lead2b.id},
              ]
            )
            result = service.call
            refute(result)
            refute(service.valid?)
            expect(service.errors.count).to eq(2)
            expect(service.errors.first[:lead]).to eq(lead2a)
            expect(service.errors.first[:error]).to eq('Agent or Current User Property mismatch with Lead')
          end
        end
        describe "to agents in another property" do
          it "should fail and do nothing" do
            service = Leads::AgentAssigner.new(
              user: property1_manager1,
              property: property1,
              assignments: [
                {agent_id: property2_agent1.id, lead_id: lead2a.id},
                {agent_id: property2_agent2.id, lead_id: lead2b.id},
              ]
            )
            result = service.call
            refute(result)
            refute(service.valid?)
            expect(service.errors.count).to eq(2)
            expect(service.errors.first[:lead]).to eq(lead2a)
            expect(service.errors.first[:error]).to eq('Agent or Current User Property mismatch with Lead')
          end
        end
      end
    end

    describe "assigning non-open leads" do
      it "is not supported" do
        lead1a.state = 'prospect'
        lead1a.save
        service = Leads::AgentAssigner.new(
          user: property1_manager1,
          property: property1,
          assignments: [
            {agent_id: property1_agent1.id, lead_id: lead1a.id},
            {agent_id: property1_agent2.id, lead_id: lead1b.id},
          ]
        )
        result = service.call
        refute(result)
        refute(service.valid?)
        expect(service.errors.count).to eq(1)
        expect(service.errors.first[:lead]).to eq(lead1a)
        expect(service.errors.first[:error]).to eq('Mass re-assignment of claimed Leads is not supported')
      end
    end

  end

end
