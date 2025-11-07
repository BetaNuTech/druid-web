require 'rails_helper'

RSpec.describe MessagePolicy, type: :policy do
  include_context "users"
  include_context "messaging"

  let(:property1) { create(:property) }
  let(:property2) { create(:property) }

  let(:agent1) do
    user = create(:user, role: property_role)
    user.confirm
    property1.assign_user(user: user, role: 'agent')
    user.reload
    user
  end

  let(:agent2) do
    user = create(:user, role: property_role)
    user.confirm
    property2.assign_user(user: user, role: 'agent')
    user.reload
    user
  end

  let(:agent1_alt) do
    # Another agent at property1, for testing reassignment
    user = create(:user, role: property_role)
    user.confirm
    property1.assign_user(user: user, role: 'agent')
    user.reload
    user
  end

  let(:system_user) do
    User.find_or_create_by!(email: 'system@bluesky.internal') do |user|
      user.password = SecureRandom.hex(20)
      user.role = Role.find_or_create_by!(name: 'Administrator', slug: 'administrator')
      user.confirmed_at = Time.current
      user.system_user = true
    end
  end

  before do
    # Ensure system user exists and has a profile
    unless system_user.profile
      system_user.create_profile!(first_name: 'Bluesky')
    end
  end

  # Leads for different scenarios
  let(:lead_assigned_to_agent1) { create(:lead, user: agent1, property: property1) }
  let(:lead_assigned_to_agent2) { create(:lead, user: agent2, property: property2) }
  let(:lead_unassigned_property1) { create(:lead, user: nil, property: property1) }
  let(:lead_unassigned_property2) { create(:lead, user: nil, property: property2) }

  describe MessagePolicy::IndexScope do
    subject { MessagePolicy::IndexScope.new(user, Message.all).resolve }

    context "when user is an agent" do
      let(:user) { agent1 }

      let!(:agent1_own_message) do
        create(:message,
          user: agent1,
          messageable: lead_assigned_to_agent1,
          message_type: email_message_type,
          body: "Agent's own message",
          subject: "Test",
          incoming: false)
      end

      let!(:system_message_to_agent1_lead) do
        create(:message,
          user: system_user,
          messageable: lead_assigned_to_agent1,
          message_type: email_message_type,
          body: "System message to agent1's lead",
          subject: "Test",
          incoming: false)
      end

      let!(:system_message_to_unassigned_lead_property1) do
        create(:message,
          user: system_user,
          messageable: lead_unassigned_property1,
          message_type: email_message_type,
          body: "System message to unassigned lead at property1",
          subject: "Test",
          incoming: false)
      end

      let!(:system_message_to_agent2_lead) do
        create(:message,
          user: system_user,
          messageable: lead_assigned_to_agent2,
          message_type: email_message_type,
          body: "System message to agent2's lead",
          subject: "Test",
          incoming: false)
      end

      let!(:agent2_own_message) do
        create(:message,
          user: agent2,
          messageable: lead_assigned_to_agent2,
          message_type: email_message_type,
          body: "Agent2's own message",
          subject: "Test",
          incoming: false)
      end

      it "includes the agent's own messages" do
        expect(subject).to include(agent1_own_message)
      end

      it "includes system messages for leads assigned to the agent" do
        expect(subject).to include(system_message_to_agent1_lead)
      end

      it "includes system messages for unassigned leads at the agent's property" do
        expect(subject).to include(system_message_to_unassigned_lead_property1)
      end

      it "does not include system messages for leads assigned to other agents" do
        expect(subject).not_to include(system_message_to_agent2_lead)
      end

      it "does not include other agents' messages" do
        expect(subject).not_to include(agent2_own_message)
      end

      context "when a lead is reassigned" do
        it "message visibility follows the new assignment" do
          # Initially, agent1 can see the system message for their lead
          expect(subject).to include(system_message_to_agent1_lead)

          # Reassign the lead to agent1_alt (another agent at the same property)
          lead_assigned_to_agent1.update!(user: agent1_alt)

          # Now agent1 should not see the system message anymore
          new_scope = MessagePolicy::IndexScope.new(agent1, Message.all).resolve
          expect(new_scope).not_to include(system_message_to_agent1_lead)

          # And agent1_alt should see it
          agent1_alt_scope = MessagePolicy::IndexScope.new(agent1_alt, Message.all).resolve
          expect(agent1_alt_scope).to include(system_message_to_agent1_lead)
        end
      end

    end

    context "when user is an administrator" do
      let(:user) { administrator }

      let!(:some_message) do
        create(:message,
          user: agent1,
          messageable: lead_assigned_to_agent1,
          message_type: email_message_type,
          body: "Some message",
          subject: "Test",
          incoming: false)
      end

      it "includes all messages" do
        expect(subject).to include(some_message)
      end
    end

    context "when user is a manager" do
      let(:manager_user) do
        user = create(:user, role: manager_role)
        user.confirm
        property1.assign_user(user: user, role: 'manager')
        user.reload
        user
      end
      let(:user) { manager_user }

      let!(:message_at_managers_property) do
        create(:message,
          user: agent1,
          messageable: lead_assigned_to_agent1,
          message_type: email_message_type,
          body: "Message at manager's property",
          subject: "Test",
          incoming: false)
      end

      let!(:message_at_other_property) do
        create(:message,
          user: agent2,
          messageable: lead_assigned_to_agent2,
          message_type: email_message_type,
          body: "Message at other property",
          subject: "Test",
          incoming: false)
      end

      it "includes messages from their properties" do
        expect(subject).to include(message_at_managers_property)
      end

      it "does not include messages from other properties" do
        expect(subject).not_to include(message_at_other_property)
      end
    end
  end
end
