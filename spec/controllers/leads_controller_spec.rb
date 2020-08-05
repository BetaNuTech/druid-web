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
        get :index, params: {lead_search: {states: ['open']}}
        expect(response).to be_successful
      end
    end

    describe "when there is an inactive property" do
      let(:active_prop) { create(:property, active: true) }
      let(:inactive_prop)  { create(:property, active: false) }
      let(:lead1) { create(:lead, property: active_prop, state: 'open') }
      let(:lead2) { create(:lead, property: inactive_prop, state: 'open') }

      describe "as an admin" do
        it "should display all leads" do
          Lead.destroy_all; lead1; lead2
          assert(Lead.count == 2)
          sign_in administrator
          get :index, params: {lead_search: {states: ['open']}}
          expect(assigns[:leads].count).to eq(2)
        end
      end

      describe "as a corporate user" do
        it "should display leads from active properties" do
          Lead.destroy_all; lead1; lead2
          assert(lead1.property.active)
          refute(lead2.property.active)
          assert(Lead.count == 2)
          sign_in corporate
          get :index, params: {lead_search: {states: ['open']}}
          expect(assigns[:leads].count).to eq(1)
        end
      end

    end

    describe "as an agent" do
      it "returns a success response" do
        sign_in agent
        lead = Lead.create! valid_attributes
        get :index, params: {lead_search: {states: ['open']}}
        expect(response).to be_successful
      end
    end

    describe "as an unroled user" do
      it "access is rejected" do
        sign_in unroled_user
        lead = Lead.create! valid_attributes
        get :index, params: {lead_search: {states: ['open']}}
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
      let(:lead) { create(:lead, property: agent.property) }
      it "returns a success reponse" do
        sign_in agent
        get :search
        expect(response).to be_redirect
        get :search, params: {lead_search: {states: ['open']}}
        expect(response).to be_successful
        get :search, params: {lead_search: {states: ['open']}}, format: :json
        expect(response).to be_successful
      end
    end
  end

  describe "GET #call_log_partial" do
    let(:lead) { create(:lead, property: agent.property) }
    describe "as an agent" do
      it "returns a success response" do
        sign_in agent
        get :call_log_partial, xhr: true, params: {id: lead.id }, format: :js
      end
    end
  end

  describe "GET #progress_state" do
    let(:lead) { Lead.create! valid_attributes }

    describe "as an agent" do
      it "returns a successful response" do
        sign_in agent
        get :progress_state, params: {id: lead.id, eventid: 'abandon' }
        expect(response).to be_successful
      end

      it "redirects to the lead if this is a 'claim'" do
        sign_in agent
        get :progress_state, params: {id: lead.id, eventid: 'claim' }
        expect(response).to redirect_to(lead_url(lead))
      end
    end
  end

  describe "GET #show" do
    let(:lead) { Lead.create! valid_attributes }

    include_examples "authenticated action", {params: {id: 0 }, name: 'show'}

    describe "when unauthenticated" do
      it "should redirect to login" do
        get :show, params: {id: lead.to_param}
        expect(response).to redirect_to(new_user_session_path)
      end
    end

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
        expect(response).to redirect_to(root_path)
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

    describe "using an entry type" do
      describe "identified as 'walkin'" do
        it "returns a success response" do
          sign_in agent
          get :new, params: {entry: :walkin}, session: valid_session
          expect(response).to have_http_status(:ok)
          expect(response).to render_template("leads/_walkin_form")
        end

        it "handles admins without a property assignment" do
          expect(administrator.properties).to be_empty
          sign_in administrator
          get :new, params: {entry: :walkin}, session: valid_session
          expect(response).to have_http_status(:ok)
          expect(response).to render_template("leads/_form")
        end
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
    include_context 'engagement_policy'

    before do
      source
    end

    describe "with an entry type: 'walkin'" do
      let(:walkin_unit) { create(:unit, property: agent.property)}
      let(:walkin_attributes) {
        {
          classification: 'lead',
          property_id: agent.property.id,
          first_comm: DateTime.now.to_s,
          first_name: 'WalkinFirst',
          last_name: 'WalkinLast',
          phone1: '5555555555',
          email: 'walkin@example.com',
          show_unit: walkin_unit.id
        }
      }

      before do
        seed_engagement_policy
        agent
        walkin_unit
      end

      it "should create a new lead" do
        sign_in agent
        lead_count = Lead.count
        post :create, params: {entry: 'walkin', lead: walkin_attributes}, session: valid_session

        expect(Lead.count).to eq(lead_count + 1)

        new_lead = assigns(:lead)
        assert(new_lead.errors.empty?)
        assert(new_lead.showing?)
        expect(new_lead.first_name).to eq(walkin_attributes[:first_name])
      end
      it "should create a new ScheduledAction to show the selected unit" do
        sign_in agent
        post :create, params: {entry: 'walkin', lead: walkin_attributes}, session: valid_session
        new_lead = assigns(:lead)
        expect(new_lead.scheduled_actions.count).to eq(2)
        showing_task = new_lead.scheduled_actions.where(lead_action: LeadAction.showing).first
        expect(showing_task.article).to eq(walkin_unit)
        expect(showing_task.lead_action).to eq(LeadAction.showing)
      end
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
          post :create, params: {lead: valid_attributes.merge(user_id: corporate.id)}, session: valid_session
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
          post :create, params: {lead: valid_attributes.merge(user_id: agent.id)}, session: valid_session
          new_lead = Lead.order(created_at: :desc).limit(1).last
          expect(new_lead.user).to eq(agent)
          expect(new_lead.property).to eq(agent.property)
          assert(new_lead.prospect?)
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

    context "creating a Lead and referral" do
      include_context 'residents'
      let(:valid_lead_attributes_for_create_with_valid_referral) {
        { lead: attributes_for(:lead, property: agent.property, user: agent).
          merge(valid_lead_attributes_with_valid_referral[:lead]) }
      }

      context "with valid lead and referral attributes" do
        it "should create the lead and referral" do
          LeadReferral.destroy_all
          sign_in agent
          post :create, params: valid_lead_attributes_for_create_with_valid_referral
          lead = assigns(:lead)
          assert lead.valid?
          expect(lead.referrals.count).to eq(1)
        end

      end
      context "with valid lead attributes and invalid referral attributes" do
        it "should create the lead but not a referral" do

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

      describe "assigning/modifying a referral from a resident" do
        include_context 'residents'

        context "with valid attributes" do
          it "should create a valid associated LeadReferral" do
            sign_in agent
            lead.referrals.destroy_all
            put :update, params: valid_lead_attributes_with_valid_referral
            lead.reload
            expect(lead.referrals.count).to eq(1)
            referral = lead.referrals.first
            expect(referral.lead_id).to eq(lead.id)
            expect(referral.note).to eq(referral_note)
            expect(referral.referrable).to eq(property1_resident1)
            expect(referral.lead_referral_source).to eq(lead_referral_source)
          end
        end

        context "with invalid attributes" do
          it "should not create an associated LeadReferral if both note and lead_referral_source_id are missing" do
            sign_in agent
            lead.referrals.destroy_all
            put :update, params: valid_lead_attributes_with_invalid_referral
            lead.reload
            expect(lead.referrals.count).to eq(0)
          end
        end

        context "deleting a lead referral" do
          it "should delete the referral when the _destroy option is set" do
            lead.referrals.destroy_all
            lead.referrals.create!(referrable: property1_resident1, lead_referral_source: lead_referral_source)
            lead.reload
            expect(lead.referrals.count).to eq(1)
            sign_in agent
            referral = lead.referrals.first
            delete_referral_params = {
              id: lead.to_param,
              lead: {
                referrals_attributes: [
                  {
                    id: referral.id,
                    _destroy: true
                  }
                ]
              }
            }
            put :update, params: delete_referral_params
            expect(response).to be_redirect
            lead.reload
            expect(lead.referrals.count).to eq(0)
          end
        end

        context "updating a lead referral" do
          it "should update the referral note" do
            lead.referrals.destroy_all
            lead.referrals.create!(referrable: property1_resident1, lead_referral_source: lead_referral_source)
            lead.reload
            sign_in agent
            referral = lead.referrals.first
            updated_referral_note = 'Updated note'
            update_referral_params = {
              id: lead.to_param,
              lead: {
                referrals_attributes: [
                  {
                    id: referral.id,
                    note: updated_referral_note
                  }
                ]
              }
            }
            put :update, params: update_referral_params
            lead.reload
            referral = lead.referrals.first
            expect(referral.note).to eq(updated_referral_note)
          end
        end
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

  describe "GET #mass_assignment" do
    let(:lead1) { create(:lead, state: 'open', property: agent.property)}
    let(:lead2) { create(:lead, state: 'open', property: agent.property)}
    let(:lead3) { create(:lead, state: 'prospect', property: agent.property, user_id: agent)}

    it "should load successfully" do
      sign_in manager
      get :mass_assignment
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST #mass_assign" do
    it "should assign leads to agents"
  end

end
