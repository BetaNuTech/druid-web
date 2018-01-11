# == Schema Information
#
# Table name: roles
#
#  id          :uuid             not null, primary key
#  name        :string
#  slug        :string
#  description :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'rails_helper'

RSpec.describe Role, type: :model do
  include_context "roles"

  it "can be initialized" do
    role = build(:role)
  end

  it "can be saved" do
    role = build(:role)
    assert role.save
  end

  it "can be updated" do
    new_name = 'foobar'
    role = create(:role)
    role.reload
    expect(role.name).to_not eq(new_name)
    role.name = new_name
    assert role.save
    expect(role.name).to eq(new_name)
  end

  it "must have a name" do
    role = build(:role)
    assert role.save
    role.name = nil
    refute role.save
  end

  it "must have a slug" do
    role = build(:role)
    assert role.save
    role.slug = nil
    refute role.save
  end

  describe "class methods" do
    it "can return the administrator instance" do
      administrator_role
      expect(Role.administrator).to eq(administrator_role)
    end

    it "can return the operator instance" do
      operator_role
      expect(Role.operator).to eq(operator_role)
    end
    it "can return the operator instance" do
      operator_role
      expect(Role.operator).to eq(operator_role)
    end

    it "can return the agent instance" do
      agent_role
      expect(Role.agent).to eq(agent_role)
    end
  end

  describe "comparisons" do

    it "should compare other roles" do
      assert administrator_role == administrator_role
      assert operator_role < administrator_role
      assert administrator_role > operator_role
      assert administrator_role > agent_role
      assert agent_role > nil
    end

    it "should compare unrecognized roles" do
      assert agent_role == agent_role
      assert agent_role > other_role
      assert administrator_role > other_role
    end
  end

  describe "identification" do
    it "should return whether the Role is administrator" do
      assert administrator_role.administrator?
      refute operator_role.administrator?
    end
    it "should return whether the Role is operator" do
      assert operator_role.operator?
      refute agent_role.operator?
    end
    it "should return whether the Role is agent" do
      assert agent_role.agent?
      refute agent_role.operator?
    end
    it "should return whether the Role is a type of administrator" do
      assert operator_role.admin?
      assert administrator_role.admin?
      refute agent_role.admin?
    end
    it "should return whether the Role is a unprivileged user" do
      refute operator_role.user?
      refute administrator_role.user?
      assert agent_role.user?
    end
  end

end
