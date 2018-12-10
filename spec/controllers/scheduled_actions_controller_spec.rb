require 'rails_helper'

RSpec.describe ScheduledActionsController, type: :controller do
  include_context "team_members"
  include_context "engagement_policy"

  before(:each) do
    seed_engagement_policy
    Lead.destroy_all
    @lead = create(:lead, state: 'open', property: team1.properties.first)
    @lead.trigger_event(event_name: 'claim', user: team1_agent1)
    @lead.reload
  end

  describe "GET #show" do
    describe "as the owner" do
      it "should display the record" do
        scheduled_action = @lead.scheduled_actions.last
        url_params = {
          id: scheduled_action.id
        }

        sign_in team1_agent1
        get :show, params: url_params
        expect(response).to be_successful
      end
    end
  end

  describe "POST #complete" do

    describe "as the scheduled action owner" do

      it "should mark a scheduled action as complete as the owner" do
        scheduled_action = @lead.scheduled_actions.pending.last
        form_attrs = {
          id: scheduled_action.id,
          scheduled_action: {
            completion_action: 'complete',
            completion_message: 'Task Completed'
          }
        }
        expect(scheduled_action.state).to eq('pending')

        sign_in team1_agent1
        post :complete, params: form_attrs
        expect(response).to be_redirect
        scheduled_action.reload
        expect(scheduled_action.state).to eq('completed')
        expect(scheduled_action.user).to eq(team1_agent1)
      end
    end

    describe "as a member of the owner's team" do
      it "should mark a scheduled action as complete as the current user" do
        scheduled_action = @lead.scheduled_actions.pending.last
        form_attrs = {
          id: scheduled_action.id,
          scheduled_action: {
            completion_action: 'complete',
            completion_message: 'Task Completed'
          }
        }
        expect(scheduled_action.state).to eq('pending')

        sign_in team1_agent2
        post :complete, params: form_attrs
        expect(response).to be_redirect
        scheduled_action.reload
        expect(scheduled_action.state).to eq('completed')
        expect(scheduled_action.user).to eq(team1_agent2)
      end

      it "should allow a team admin to complete the task as the original owner" do
        scheduled_action = @lead.scheduled_actions.pending.last
        form_attrs = {
          id: scheduled_action.id,
          scheduled_action: {
            completion_action: 'complete',
            completion_message: 'Task Completed',
            impersonate: '1'
          }
        }
        expect(scheduled_action.state).to eq('pending')

        sign_in team1_lead1
        post :complete, params: form_attrs
        expect(response).to be_redirect
        scheduled_action.reload
        expect(scheduled_action.state).to eq('completed')
        expect(scheduled_action.user).to eq(@lead.user)
      end
    end

    describe "as an agent in a different team" do
      it "should not mark a scheduled action as complete" do
        scheduled_action = @lead.scheduled_actions.pending.last
        form_attrs = {
          id: scheduled_action.id,
          scheduled_action: {
            completion_action: 'complete',
            completion_message: 'Task Completed'
          }
        }
        expect(scheduled_action.state).to eq('pending')

        sign_in team2_agent1
        post :complete, params: form_attrs
        expect(response).to be_redirect
        scheduled_action.reload
        expect(scheduled_action.state).to eq('pending')
      end
    end
  end
end
