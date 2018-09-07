RSpec.shared_context "team_members" do
  include_context "users"
  include_context "roles"
  include_context "teamroles"

  let(:team1) { create(:team) }
  let(:team_property1) { create(:property, team: team1) }
  let(:team1_agent1) {
    user = create(:user)
    user.role = agent_role
    TeamUser.create!(team: team1, user: user, teamrole: agent_teamrole )
    user.reload
    user
  }
  let(:team1_agent2) {
    user = create(:user)
    user.role = agent_role
    TeamUser.create!(team: team1, user: user, teamrole: agent_teamrole)
    user.reload
    user
  }
  let(:team1_lead1) {
    user = create(:user)
    user.role = agent_role
    TeamUser.create!(team: team1, user: user, teamrole: lead_teamrole)
    user.reload
    user
  }
  let(:team1_manager1) {
    user = create(:user)
    user.role = manager_role
    TeamUser.create!(team: team1, user: user, teamrole: manager_teamrole)
    user.reload
    user
  }
  let(:team1_corporate1) {
    user = create(:user)
    user.role = corporate_role
    TeamUser.create!(team: team1, user: user, teamrole: none_teamrole)
    user.reload
    user
  }
end
