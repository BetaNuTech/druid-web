require 'rails_helper'

RSpec.describe TeamsController, type: :controller do
  include_context "users"
  render_views

  describe "GET #index" do
    describe "as a corporate user" do
      it "should be successful" do
        sign_in corporate
        get :index, params: {}
        expect(response).to be_successful
      end
    end
  end

  describe "GET #new" do
    describe "as a corporate user" do
      it "should be successful" do
        sign_in corporate
        subject = get :new, params: {}
        expect(subject).to be_successful
      end
    end
  end

  describe "POST #create" do
    describe "as a corporate user" do
      it "should be successful" do
        team_count = Team.count
        sign_in corporate
        subject = post :create, params: {
          team: {
            name: 'New Team 1',
            description: 'Test Team 1'
          }
        }
        last_team = Team.order("created_at desc").first
        expect(subject).to redirect_to(team_url(last_team))
        expect(Team.count).to eq(team_count + 1)
      end
    end
  end

  describe "GET #edit" do
    let(:team) { create(:team) }

    describe "as a corporate user" do
      it "should be successful" do
        sign_in corporate
        get :edit, params: {id: team.id}
        expect(response).to be_successful
      end
    end
  end

  describe "PUT #update" do
    let(:team) { create(:team)}
    let(:teamrole1) { create(:teamrole) }
    let(:teamuser1) { create(:user) }

    describe "as a corporate user" do
      before do
        sign_in corporate
      end

      it "should let the name be updated" do
        old_name = team.name
        new_name = 'NewName'
        subject = put :update, params: {id: team.id, team: {name: new_name}}
        expect(subject).to redirect_to(team_url(team))
        team.reload
        expect(team.name).to eq(new_name)
      end

      it "should let the description be updated" do
        old_description = team.description
        new_description = 'Newdescription'
        subject = put :update, params: {id: team.id, team: {description: new_description}}
        expect(subject).to redirect_to(team_url(team))
        team.reload
        expect(team.description).to eq(new_description)
      end

      it "should allow a member to be added" do
        old_count = team.members.count
        subject = put :update, params: {
          id: team.id,
          team: {
            memberships_attributes: [
              {
                teamrole_id: teamrole1.id,
                user_id: teamuser1.id
              }
            ]
          }
        }
        expect(subject).to redirect_to(team_url(team))
        team.reload
        expect(team.members.count).to eq(old_count + 1)
        expect(team.members.to_a.include?(teamuser1))
      end

      it "should allow a member to be removed" do
        TeamUser.create(user: teamuser1, team: team, teamrole: teamrole1)
        team.reload
        expect(team.members.to_a.include?(teamuser1))
        old_count = team.members.count
        membership = team.memberships.first
        subject = put :update, params: {
          id: team.id,
          team: {
            memberships_attributes: {
              "0" => {
                id: membership.id,
                teamrole_id: membership.teamrole_id,
                user_id: membership.user.id,
                _destroy: "1"
              }
            }
          }
        }
        expect(subject).to redirect_to(team_url(team))
        team.reload
        expect(team.members.count).to eq(old_count - 1)
        refute(team.members.to_a.include?(teamuser1))
      end
    end
  end

  describe "DELETE #delete" do
    describe "as a corporate user" do
      it "should be successful" do
        team = create(:team)
        team_count = Team.count
        sign_in corporate
        subject = delete :destroy, params: {id: team.id}
        expect(subject).to redirect_to(teams_url)
        expect(Team.count).to eq(team_count - 1)
      end
    end
  end


end
