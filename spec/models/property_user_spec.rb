# == Schema Information
#
# Table name: property_users
#
#  id          :uuid             not null, primary key
#  property_id :uuid
#  user_id     :uuid
#  role        :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'rails_helper'

RSpec.describe PropertyUser, type: :model do
  include_context "users"
  include_context "engagement_policy"

  let(:property){ create(:property) }
  let(:user) { agent }
  let(:property_user) { build(:property_user, user: user, property: property)}

  describe "associations" do
    it "has a user" do
      expect(property_user.user).to eq(user)
    end

    it "has a property" do
      expect(property_user.property).to eq(property)
    end
  end

  describe "validations" do
    let(:property) { create(:property) }
    let(:property2) { create(:property) }
    let(:user) { create(:user) }

    it "has a role" do
      pu = PropertyUser.new(user: user, property: property, role: 'agent')
      assert(pu.valid?)
      pu.role = nil
      refute(pu.valid?)
    end

    it "is unique within a property" do
      PropertyUser.create(user: user, property: property, role: 'agent')
      pu = PropertyUser.new(user: user, property: property, role: 'manager')
      refute(pu.valid?)
      pu.property = property2
      assert(pu.valid?)
    end
  end

  describe "roles" do
    it "has a role" do
      expect(property_user.role).to eq('agent')
    end

    it "must have a role" do
      assert property_user.valid?
      property_user.role = nil
      refute property_user.valid?
    end

    it "can be an agent" do
      property_user.role = 'agent'
      expect(property_user.role).to eq('agent')
    end

    it "can be a manager" do
      property_user.role = 'manager'
      expect(property_user.role).to eq('manager')
    end

    it "cannot be assigned an invalid role" do
      expect{
        property_user.role = 'invalid role'
      }.to raise_error(ArgumentError)
    end

  end

  describe "upon deletion" do
    let(:property1) { create(:property) }
    let(:property2) { create(:property) }
    let(:manager) {
      user = create(:user, role: Role.manager)
      property1.assign_user(user: user, role: PropertyUser::MANAGER_ROLE)
      user.reload
      user
    }
    let(:agent) {
      user = create(:user, role: Role.property)
      property1.assign_user(user: user, role: PropertyUser::AGENT_ROLE)
      user.reload
      user
    }
    let(:lead) { create(:lead, property: property1, state: 'open')}
    it "should reassign scheduled actions to primary agent" do
      seed_engagement_policy
      assert(user.properties = [property1])
      assert(manager.properties = [property1])
      lead.trigger_event(event_name: 'claim', user: agent)
      agent.reload
      manager_action_count = manager.tasks_pending.count
      agent_action_count = agent.tasks_pending.count
      expect(agent_action_count).to eq(1)
      agent.assignments.destroy_all
      agent.reload
      manager.reload
      expect(agent.tasks_pending.count).to eq(0)
      expect(manager.scheduled_actions.count).to eq(manager_action_count + agent_action_count)
    end
  end

end
