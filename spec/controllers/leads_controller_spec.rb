require 'rails_helper'

RSpec.describe LeadsController, type: :controller do
  include_context "users"
  render_views

  let(:source) {
    create(:lead_source, slug: LeadSource::DEFAULT_SLUG)
  }

  # This should return the minimal set of attributes required to create a valid
  # Lead. As you add validations to Lead, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    attributes_for(:lead).merge(state: 'open', property_id: agent.property.id, lead_source_id: source.id)
  }

  let(:invalid_attributes) {
    attrs = attributes_for(:lead)
    attrs[:first_name] = nil
    attrs
  }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # LeadsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  before do
    source
  end


  describe "GET #index" do
    include_examples "authenticated action", {params: {}, name: 'index'}

    describe "as an corporate" do
      it "returns a success response" do
        sign_in corporate
        lead = Lead.create! valid_attributes
        get :index, params: {}
        expect(response).to be_successful
      end

    end

    describe "as an agent" do
      it "returns a success response" do
        sign_in agent
        lead = Lead.create! valid_attributes
        get :index, params: {}
        expect(response).to be_successful
      end

    end

    describe "as an unroled user" do
      it "access is rejected" do
        sign_in unroled_user
        lead = Lead.create! valid_attributes
        get :index, params: {}
        expect(response).to be_redirect
      end
    end

    describe "using search" do
      let(:lead1) { create(:lead, first_name: "YYY LeadPerson", property: agent.property)}
      let(:lead2) { create(:lead, first_name: "ZZZ LeadPerson", property: agent.property)}
      let(:lead3) { create(:lead, first_name: "ZZZ LeadPerson", property: create(:property))}

      describe "with a text query" do
        it "searches against a full text field" do
          lead1; lead2; lead3
          sign_in agent
          get :index, params: {lead_search: {text: "LeadPerson"}}
          expect(response.body).to match("2 records found")
          expect(response.body).to match(/YYY/)
          expect(response.body).to match(/ZZZ/)
          get :index, params: {lead_search: {text: "YYY"}}
          expect(response.body).to match("1 record found")
          expect(response.body).to match(/YYY/)
          expect(response.body).to_not match(/ZZZ/)
        end
      end
    end

  end

  describe "GET #search" do
    describe "as an agent" do
      it "returns a success reponse" do
        sign_in agent
        get :search, params: {}
        expect(response).to be_successful
        get :search, params: {}, format: :json
        expect(response).to be_successful
      end
    end
  end

  describe "GET #show" do
    let(:lead) { Lead.create! valid_attributes }

    include_examples "authenticated action", {params: {id: 0 }, name: 'show'}

    describe "as an corporate" do
      it "returns a success response" do
        sign_in corporate
        get :show, params: {id: lead.to_param}
        expect(response).to be_successful
      end

      it "can return JSON data" do
        sign_in corporate
        assert(lead.preference.present?)
        get :show, params: {id: lead.to_param}, format: :json
        expect(response).to be_successful
      end
    end

    describe "as an agent" do
      it "returns a success response" do
        sign_in agent
        get :show, params: {id: lead.to_param}
        expect(response).to be_successful
      end

      it "can return JSON data" do
        sign_in agent
        assert(lead.preference.present?)
        get :show, params: {id: lead.to_param}, format: :json
        expect(response).to be_successful
      end
    end

    describe "as an unroled user" do
      it "denies access" do
        sign_in unroled_user
        get :show, params: {id: lead.to_param}
        expect(response).to be_redirect
      end
    end

  end

  describe "GET #new" do
    include_examples "authenticated action", {params: {id: 0 }, name: 'new'}

    describe "as an corporate" do
      it "returns a success response" do
        sign_in corporate
        get :new, params: {}, session: valid_session
        expect(response).to be_successful
      end
    end

    describe "as an agent" do
      it "returns a success response" do
        sign_in agent
        get :new, params: {}, session: valid_session
        expect(response).to be_successful
      end
    end

    describe "as an unroled user" do
      it "denies access" do
        sign_in unroled_user
        get :new, params: {}, session: valid_session
        expect(response).to be_redirect
      end
    end

  end

  describe "GET #edit" do
    include_examples "authenticated action", {params: {id: 0 }, name: 'edit'}

    describe "as an corporate" do
      it "returns a success response" do
        sign_in corporate
        lead = Lead.create! valid_attributes
        get :edit, params: {id: lead.to_param}, session: valid_session
        expect(response).to be_successful
      end
    end

    describe "as an agent" do
      it "returns a success response" do
        sign_in agent
        lead = Lead.create! valid_attributes
        get :edit, params: {id: lead.to_param}, session: valid_session
        expect(response).to be_successful
      end
    end

    describe "as an unroled user" do
      it "denies access" do
        sign_in unroled_user
        lead = Lead.create! valid_attributes
        get :edit, params: {id: lead.to_param}, session: valid_session
        expect(response).to be_redirect
      end
    end

  end

  describe "POST #create" do
    include_examples "authenticated action", {params: {id: 0 }, name: 'create'}

    before do
      source
    end

    describe "as an corporate" do
      context "with valid params" do
        it "creates a new Lead" do
          sign_in corporate
          expect {
            post :create, params: {lead: valid_attributes}, session: valid_session
          }.to change(Lead, :count).by(1)
        end

        it "creates a new Lead" do
          sign_in corporate
          post :create, params: {lead: valid_attributes}, session: valid_session
          new_lead = Lead.order(created_at: :desc).limit(1).last
          expect(new_lead.user).to eq(corporate)
        end
      end
    end

    describe "as an agent" do
      context "with valid params" do
        it "creates a new Lead" do
          sign_in agent
          expect {
            post :create, params: {lead: valid_attributes}, session: valid_session
          }.to change(Lead, :count).by(1)
        end

        it "creates a new Lead" do
          sign_in agent
          post :create, params: {lead: valid_attributes}, session: valid_session
          new_lead = Lead.order(created_at: :desc).limit(1).last
          expect(new_lead.user).to eq(agent)
        end
      end
    end

    describe "as an unroled user" do
      context "with valid params" do
        it "denies access and does not create a new Lead" do
          sign_in unroled_user
          expect {
            post :create, params: {lead: valid_attributes}, session: valid_session
          }.to change(Lead, :count).by(0)
        end
      end
    end

    describe "as an agent" do
      context "with valid params" do
        it "creates a new Lead" do
          sign_in agent
          expect {
            post :create, params: {lead: valid_attributes}, session: valid_session
          }.to change(Lead, :count).by(1)
        end

        it "redirects to the created lead" do
          sign_in agent
          post :create, params: {lead: valid_attributes}, session: valid_session
          expect(response).to redirect_to(Lead.last)
        end

        context "specifying a source id" do
          it "creates a lead with the source" do
            sign_in agent
            post :create, params: {lead: valid_attributes.merge(lead_source_id: source.id) }, session: valid_session
            expect(response).to redirect_to(Lead.last)
            expect(Lead.last.source).to eq(source)
          end
        end
      end

      context "with invalid params" do
        it "returns a success response (i.e. to display the 'new' template)" do
          sign_in agent
          post :create, params: {lead: invalid_attributes}, session: valid_session
          expect(response).to be_successful
        end
      end
    end

  end

  describe "PUT #update" do
    include_examples "authenticated action", {params: {id: 0 }, name: 'update'}

    let(:new_attributes) { attributes_for(:lead).merge(notes: 'Foobar') }

    describe "as an agent" do
      context "with valid params" do
        it "updates the requested lead" do
          sign_in agent
          lead = Lead.create! valid_attributes
          put :update, params: {id: lead.to_param, lead: new_attributes}, session: valid_session
          lead.reload
          expect(lead.notes).to eq(new_attributes[:notes])
        end

        it "redirects to the lead" do
          sign_in agent
          lead = Lead.create! valid_attributes
          put :update, params: {id: lead.to_param, lead: valid_attributes}, session: valid_session
          expect(response).to redirect_to(lead)
        end
      end

      context "with invalid params" do
        it "returns a success response (i.e. to display the 'edit' template)" do
          sign_in agent
          lead = Lead.create! valid_attributes
          put :update, params: {id: lead.to_param, lead: invalid_attributes}
          expect(response).to be_successful
        end
      end

      it "allows Lead owner to reassign the Lead to another User" do
        sign_in agent
        lead = Lead.create! valid_attributes
        lead.user = agent
        lead.save!
        put :update, params: {id: lead.to_param, lead: {user_id: corporate.id}}
        lead.reload
        expect(lead.user).to eq(corporate)
      end

      it "disallows Lead owner from claiming the Lead from another User" do
        sign_in agent
        lead = Lead.create! valid_attributes
        lead.user = corporate
        lead.save!
        put :update, params: {id: lead.to_param, lead: {user_id: agent.id}}
        lead.reload
        expect(lead.user).to eq(corporate)
      end

    end

    describe "as an corporate" do
      context "with valid params" do
        it "updates the requested lead" do
          sign_in corporate
          lead = Lead.create! valid_attributes
          put :update, params: {id: lead.to_param, lead: new_attributes}, session: valid_session
          lead.reload
          expect(lead.notes).to eq(new_attributes[:notes])
        end
      end
    end

    describe "as an unroled user" do
      context "with valid params" do
        it "does not update the requested lead" do
          sign_in unroled_user
          lead = Lead.create! valid_attributes
          put :update, params: {id: lead.to_param, lead: new_attributes}, session: valid_session
          lead.reload
          expect(lead.notes).to_not eq(new_attributes[:notes])
        end
      end

    end

  end

  describe "DELETE #destroy" do
    it "redirects to login if unauthenticated" do
      lead = Lead.create! valid_attributes
      delete :destroy, params: {id: lead.to_param}, session: valid_session
      expect(response).to redirect_to(new_user_session_path)
    end

    describe "as an corporate" do
      it "destroys the requested lead" do
        sign_in corporate
        lead = Lead.create! valid_attributes
        expect {
          delete :destroy, params: {id: lead.to_param}, session: valid_session
        }.to change(Lead, :count).by(-1)
      end
    end

    describe "as an agent" do

      describe "as the owner" do
        let(:lead) {Lead.create! valid_attributes.merge(user_id: agent.id)}
        it "destroys the requested lead" do
          sign_in agent
          lead
          expect {
            delete :destroy, params: {id: lead.to_param}, session: valid_session
          }.to change(Lead, :count).by(-1)
        end

        it "redirects to the leads list" do
          sign_in agent
          lead
          delete :destroy, params: {id: lead.to_param}, session: valid_session
          expect(response).to redirect_to(leads_url)
        end
      end

      describe "as an admin" do
        it "destroys the requested lead" do
          sign_in corporate
          lead = Lead.create! valid_attributes.merge(user_id: agent.id)
          expect {
            delete :destroy, params: {id: lead.to_param}, session: valid_session
          }.to change(Lead, :count).by(-1)
        end
      end

      describe "as the property manager" do
        it "destroys the requested lead" do
          sign_in manager
          lead = Lead.create! valid_attributes.merge(user_id: agent.id)
          expect {
            delete :destroy, params: {id: lead.to_param}, session: valid_session
          }.to change(Lead, :count).by(-1)
        end
      end

      describe "as an agent from another property" do
        it "does not destroy the requested lead" do
          sign_in agent2
          lead = Lead.create! valid_attributes.merge(user_id: agent.id)
          expect {
            delete :destroy, params: {id: lead.to_param}, session: valid_session
          }.to change(Lead, :count).by(0)
        end
      end

    end

    describe "as an unroled user" do
      it "does not destroy the requested lead" do
        sign_in unroled_user
        lead = Lead.create! valid_attributes
        expect {
          delete :destroy, params: {id: lead.to_param}, session: valid_session
        }.to change(Lead, :count).by(0)
      end
    end
  end

  describe "POST #trigger_state_event" do
    let(:lead) { create(:lead, state: 'open', user_id: agent.id) }

    it "should deny access if unauthorized" do
      # POST without any authentication
      post :trigger_state_event, params: { id: lead.to_param, eventid: 'claim'}, format: :js
      expect(response.status).to eq(401)

      # POST as an unroled/unauthorized user
      sign_in unroled_user
      post :trigger_state_event, params: { id: lead.to_param, eventid: 'claim'}, format: :js
      expect(response).to be_redirect
    end

    it "should trigger event if the event is valid" do
      sign_in agent
      post :trigger_state_event, params: { id: lead.to_param, eventid: 'claim'}, format: :js
      expect(response).to be_successful
      lead.reload
      assert lead.prospect?
      expect(lead.user).to eq(agent)
    end

    it "should gracefully handle an invalid event" do
      sign_in agent
      post :trigger_state_event, params: { id: lead.to_param, eventid: 'invalid'}, format: :js
      expect(response).to be_successful
    end

  end

  describe "POST #update_state" do
    let(:lead) { create(:lead, state: 'open', property_id: agent.property.id) }

    it "should update the lead state" do
      sign_in agent
      post :update_state,
        params: { id: lead.id,
                  memo: 'foobar',
                  classification: 'lead',
                  eventid: 'claim' }
      lead.reload
      expect(response).to be_redirect
      expect(lead.state).to eq('prospect')
    end

    it "should assign a follow_up_at when the Lead is 'postponed'" do
      lead.state = 'prospect'
      lead.user = agent
      lead.save

      sign_in agent
      post :update_state,
        params: { id: lead.id,
                  memo: 'foobar',
                  classification: 'lead',
                  eventid: 'postpone',
                  follow_up_at: {'(1i)': 2018, '(2i)': 12, '(3i)': 1}
                }
      lead.reload
      expect(response).to be_redirect
      expect(lead.state).to eq('future')
      expect(lead.follow_up_at).to eq(DateTime.new(2018,12,1))
    end


  end

end
