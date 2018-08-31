require 'rails_helper'
RSpec.describe UsersHelper, type: :helper do
  include_context "users"

  describe "roles_for_select" do
    before do
      administrator
      corporate
      agent
    end

    it "should return all roles if the editor is an administrator" do
      out = roles_for_select(user: agent, editor: administrator, value: agent.role.id)
      expect(out).to match(administrator_role.id)
      expect(out).to match(administrator_role.name)
      expect(out).to match(corporate_role.id)
      expect(out).to match(corporate_role.name)
      expect(out).to match(agent_role.id)
      expect(out).to match(agent_role.name)
    end

    it "should return all roles lower than the editor role" do
      out = roles_for_select(user: agent, editor: corporate, value: agent.role.id)
      expect(out).to_not match(administrator_role.id)
      expect(out).to_not match(administrator_role.name)
      expect(out).to match(corporate_role.id)
      expect(out).to match(corporate_role.name)
      expect(out).to match(agent_role.id)
      expect(out).to match(agent_role.name)
    end

    it "should select the provided role" do
      out = roles_for_select(user: agent, editor: corporate, value: agent.role.id)
      expect(out).to match(("selected=\"selected\" value=\"#{agent.role.id}\""))
    end

    it "should return an empty string if the editor has no role" do
      corporate.role = nil
      corporate.save
      out = roles_for_select(user: agent, editor: corporate, value: agent.role.id)
      expect(out).to be_empty
    end

  end

end
