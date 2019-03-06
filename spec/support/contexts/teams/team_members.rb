RSpec.shared_context "team_members" do
  include_context "users"
  include_context "roles"
  include_context "teamroles"

  let(:team1) { team = create(:team) }
  let(:team2) { create(:team) }
  let(:team_property1) { create(:property, team: team1) }
  let(:team_property2) { create(:property, team: team1) }
  let(:team2_property3) { create(:property, team: team2) }

  before(:each) do
    team_property1
    team_property2
    team2_property3
  end

  let(:team1_agent1) {
    user = create(:user)
    user.role = property_role
    user.save
    TeamUser.create!(team: team1, user: user, teamrole: agent_teamrole )
    user.reload
    user.confirm
    team_property1.assign_user(user: user, role: 'agent')
    user.reload
    user
  }
  let(:team1_agent2) {
    user = create(:user)
    user.role = property_role
    user.save
    TeamUser.create!(team: team1, user: user, teamrole: agent_teamrole)
    user.reload
    user.confirm
    team_property2.assign_user(user: user, role: 'agent')
    user.reload
    user
  }
  let(:team1_agent3) {
    user = create(:user)
    user.role = property_role
    user.save
    TeamUser.create!(team: team1, user: user, teamrole: agent_teamrole)
    user.reload
    user.confirm
    team_property1.assign_user(user: user, role: 'agent')
    user.reload
    user
  }
  let(:team1_manager1) {
    user = create(:user)
    user.role = manager_role
    user.save
    TeamUser.create!(team: team1, user: user, teamrole: agent_teamrole)
    user.reload
    user.confirm
    team_property1.assign_user(user: user, role: 'manager')
    user.reload
    user
  }
  let(:team1_lead1) {
    user = create(:user)
    user.role = property_role
    user.save
    TeamUser.create!(team: team1, user: user, teamrole: lead_teamrole)
    user.reload
    user.confirm
    user
  }
  let(:team1_lead2) {
    user = create(:user)
    user.role = property_role
    user.save
    TeamUser.create!(team: team1, user: user, teamrole: lead_teamrole)
    user.reload
    user.confirm
    user
  }
  let(:team1_corporate1) {
    user = create(:user)
    user.role = corporate_role
    user.save
    TeamUser.create!(team: team1, user: user, teamrole: none_teamrole)
    user.reload
    user.confirm
    user
  }
  let(:team2_agent1) {
    user = create(:user)
    user.role = property_role
    user.save
    TeamUser.create!(team: team2, user: user, teamrole: agent_teamrole )
    user.reload
    user.confirm
    team2_property3.assign_user(user: user, role: 'agent')
    user.reload
    user
  }
  let(:team2_agent2) {
    user = create(:user)
    user.role = property_role
    user.save
    TeamUser.create!(team: team2, user: user, teamrole: agent_teamrole)
    user.reload
    user.confirm
    team2_property3.assign_user(user: user, role: 'agent')
    user.reload
    user
  }
  let(:team2_lead1) {
    user = create(:user)
    user.role = property_role
    user.save
    TeamUser.create!(team: team2, user: user, teamrole: lead_teamrole)
    user.reload
    user.confirm
    user
  }
  let(:team2_lead2) {
    user = create(:user)
    user.role = property_role
    user.save
    TeamUser.create!(team: team2, user: user, teamrole: lead_teamrole)
    user.reload
    user.confirm
    user
  }
  let(:team2_manager1) {
    user = create(:user)
    user.role = manager_role
    user.save
    TeamUser.create!(team: team2, user: user, teamrole: manager_teamrole)
    user.reload
    user.confirm
    team2_property3.assign_user(user: user, role: 'manager')
    user.reload
    user
  }
  let(:team2_manager2) {
    user = create(:user)
    user.role = manager_role
    user.save
    TeamUser.create!(team: team2, user: user, teamrole: manager_teamrole)
    user.reload
    user.confirm
    team2_property3.assign_user(user: user, role: 'manager')
    user.reload
    user
  }
  let(:team2_corporate1) {
    user = create(:user)
    user.role = corporate_role
    user.save
    TeamUser.create!(team: team2, user: user, teamrole: none_teamrole)
    user.reload
    user.confirm
    user
  }
end
