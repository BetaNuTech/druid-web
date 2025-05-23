require 'rails_helper'

RSpec.describe ScheduledActionsController, type: :controller do
  include_context "team_members"
  include_context "engagement_policy"
  include_context "messaging"
  render_views

  let(:scheduled_action) { create(:scheduled_action, user: team1_agent1) }
  let(:schedule_attributes) {
    {"rule"=>"singular",
     "date(1i)"=>"2023",
     "date(2i)"=>"1",
     "date(3i)"=>"11",
     "day"=>[""],
     "day_of_week"=>{"monday"=>[""], "tuesday"=>[""], "wednesday"=>[""], "thursday"=>[""], "friday"=>[""], "saturday"=>[""], "sunday"=>[""]},
     "time(1i)"=>"2023",
     "time(2i)"=>"1",
     "time(3i)"=>"11",
     "time(4i)"=>"9",
     "time(5i)"=>"33",
     "interval"=>"1",
     "until(1i)"=>"2023",
     "until(2i)"=>"1",
     "until(3i)"=>"11",
     "until(4i)"=>"09",
     "until(5i)"=>"33",
     "count"=>"0",
     "duration"=>"0"}
  }
  let(:valid_attributes) {
    {
      target_id: @lead.id, target_type: 'Lead',
      user_id: user.id,
      lead_action_id: lead_action.id,
      description: 'Test action',
      schedule_attributes: schedule_attributes
    }
  }

  before(:each) do
    seed_engagement_policy
    Lead.destroy_all
    @lead = create(:lead, state: 'open', property_id: team1_agent1.property.id)
    @lead.trigger_event(event_name: 'claim', user: team1_agent1)
    @lead.reload
  end

  describe "GET #index" do
    let(:lead) {
      lead = create(:lead, property: agent.property)
      lead.trigger_event(event_name: 'claim', user: agent)
      lead.reload
      lead
    }

    it "should display scheduled actions for user" do
      sign_in agent
      get :index
      expect(response).to be_successful
    end

    it "should display scheduled actions for a lead" do
      sign_in manager
      get :index, params: {lead_id: lead.id}
      expect(response).to be_successful
    end

    it "should display scheduled actions for an agent" do
      sign_in manager
      get :index, params: {user_id: agent.id}
      expect(response).to be_successful
    end

    it "should display scheduled actions for all" do
      sign_in agent
      get :index, params: {all: true}
      expect(response).to be_successful
    end

    it "should reject requests to unauthorized users" do
      sign_in agent2
      get :index, params: {lead_id: lead.id}
      expect(response).to_not be_successful
      get :index, params: {user_id: agent.id}
      expect(response).to_not be_successful
    end
  end

  describe "GET #new" do
    describe "as an agent" do
      it "should be successful" do
        sign_in agent
        get :new
        expect(response).to be_successful
      end
    end
  end

  describe "GET #show" do
    describe "as the owner" do
      it "should display the record" do
        scheduled_action = @lead.scheduled_actions.last
        url_params = { id: scheduled_action.id }
        sign_in agent
        get :show, params: url_params
        expect(response).to be_successful
      end
    end
  end

  describe "GET #edit" do
    describe "as the owner" do
      it "should be successful" do
        expect(scheduled_action.user).to eq(team1_agent1)
        url_params = { id: scheduled_action.id }
        sign_in team1_agent1
        get :edit, params: url_params
        expect(response).to be_successful
      end
    end
  end

  describe "PUT #update" do
    describe "as the owner" do
      it "should be successful" do
        new_description =  'Foobar123'
        url_params = { id: scheduled_action.id, scheduled_action: {description: new_description} }
        sign_in team1_agent1
        put :update, params: url_params
        expect(response).to be_redirect
        scheduled_action.reload
        expect(scheduled_action.description).to eq(new_description)
      end
    end
  end

  describe "POST #create" do
    describe "as the owner" do
      let(:user) { team1_agent1 }
      let(:lead_action) { LeadAction.first }
      it "should be successful" do
        sign_in team1_agent1
        expect{
          post :create, params: {scheduled_action: valid_attributes } 
        }.to change{ScheduledAction.count}
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

    describe "as a member of the owner's property" do
      it "should mark a scheduled action as complete as the current user" do
        scheduled_action = @lead.scheduled_actions.pending.last
        assert(@lead.property == team1_agent3.property)
        form_attrs = {
          id: scheduled_action.id,
          scheduled_action: {
            completion_action: 'complete',
            completion_message: 'Task Completed'
          }
        }
        expect(scheduled_action.state).to eq('pending')

        sign_in team1_agent3
        post :complete, params: form_attrs
        expect(response).to be_redirect
        scheduled_action.reload
        expect(scheduled_action.state).to eq('completed')
        expect(scheduled_action.user).to eq(team1_agent3)
      end

      it "should allow the property manager to complete the task as the original owner" do
        scheduled_action = @lead.scheduled_actions.pending.last
        assert(@lead.property == team1_manager1.property)
        form_attrs = {
          id: scheduled_action.id,
          scheduled_action: {
            completion_action: 'complete',
            completion_message: 'Task Completed',
            impersonate: '1'
          }
        }
        expect(scheduled_action.state).to eq('pending')

        sign_in team1_manager1
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

  describe "GET #conflict_check" do
    it "should return 'true' when no conflict exists for the calling user" do
    end

    it "should return 'true' when a conflict exists for the calling user" do
    end
  end

end
