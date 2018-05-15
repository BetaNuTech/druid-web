# == Schema Information
#
# Table name: property_agents
#
#  id          :uuid             not null, primary key
#  user_id     :uuid
#  property_id :uuid
#  active      :boolean          default(TRUE)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  title       :string
#

require 'rails_helper'

RSpec.describe PropertyAgent, type: :model do
  let(:valid_attributes) {
    attributes_for(:property_agent)
  }

  describe "Validations" do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:property1) { create(:property) }
    let(:property2) { create(:property) }

    it "can be saved with valid attributes" do
      agent = PropertyAgent.new(user: user1, property: property1)
      assert agent.save
    end

    it "does not allow duplicate users per property" do
      agent1 = build(:property_agent, {user: user1, property: property1 })
      assert agent1.save

      agent2 = build(:property_agent, {user: user1, property: property1 })
      refute agent2.save
      agent2.property = property2
      assert agent2.save
    end

  end

  describe "Associations" do
    let(:property_agent) { create(:property_agent) }

    it "has a user" do
      assert property_agent.user.is_a?(User)
    end

    it "has a property" do
      assert property_agent.property.is_a?(Property)
    end

  end
end
