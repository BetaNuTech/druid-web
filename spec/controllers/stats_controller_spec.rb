#require 'rails_helper'

#RSpec.describe StatsController, type: :controller do
  #include_context "users"
  #render_views

  #describe "GET #manager" do
    #let(:default_lead_source) { create(:lead_source, slug: LeadSource::DEFAULT_SLUG) }
    #let(:lead1) { create(:lead, property: agent.property, source: default_lead_source, state: 'open') }
    #let(:lead2) { create(:lead, property: agent.property, source: default_lead_source, state: 'open') }
    #let(:lead3) { create(:lead, property: agent2.property, source: default_lead_source, state: 'open') }
    #let(:lead4) { create(:lead, property: agent2.property, state: 'open')}

    #before do
      #lead1; lead2; lead3; lead4
      #lead1.trigger_event(event_name: 'work', user: agent)
    #end

    #it "should be successful" do
      #sign_in manager
      #get :manager, format: :json
      #expect(response).to be_successful
    #end

    #it "filters by date" do
      #sign_in manager
      #get :manager, params: {date_range: '2weeks'}, format: :json
      #expect(response).to be_successful
    #end

    #it "filters by property" do
      #sign_in manager
      #get :manager, params: {property_ids: [agent.property.id]}, format: :json
      #expect(response).to be_successful
    #end

    #it "filters by users" do
      #sign_in manager
      #get :manager, params: {user_ids: [agent.id]}, format: :json
      #expect(response).to be_successful
    #end
  #end
#end
