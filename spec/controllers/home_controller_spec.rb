require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  include_context "users"
  render_views

  before(:each) do
    create(:lead)
  end

  describe "when unauthenticated" do
    it "redirects to the login page at the root path" do
      get :dashboard
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "when authenticated" do
    it "renders the dashboard page" do
      sign_in agent
      get :dashboard
      #expect(response).to be_redirect
      expect(response).to render_template(:dashboard)
    end

    #describe "as an administrator" do
      #before do
        #sign_in administrator
      #end

      #describe "the navigation bar" do
        #it "displays a link to User Management" do
          #get :dashboard
          #expect(response).to be_successful
          #expect(response.body).to match("Manage Bluesky Users")
        #end

        #it "displays a link to Role Management" do
          #get :dashboard
          #expect(response).to be_successful
          #expect(response.body).to match("Manage User Roles")
        #end

        #it "displays a link to LeadSource Management" do
          #get :dashboard
          #expect(response).to be_successful
          #expect(response.body).to match("Lead Sources")
        #end

        #it "displays a link to Property Management" do
          #get :dashboard
          #expect(response).to be_successful
          #expect(response.body).to match("Properties")
        #end

        #it "displays a link to Lead Management" do
          #get :dashboard
          #expect(response).to be_successful
          #expect(response.body).to match("Create Lead")
        #end
      #end
    #end

    #describe "as an corporate" do
      #before do
        #sign_in corporate
      #end

      #describe "the navigation bar" do
        #it "displays a link to User Management" do
          #get :dashboard
          #expect(response).to be_successful
          #expect(response.body).to match("Manage Bluesky Users")
        #end

        #it "does not display a link to Role Management" do
          #get :dashboard
          #expect(response).to be_successful
          #expect(response.body).to_not match("Manage User Roles")
        #end

        #it "displays a link to LeadSource Management" do
          #get :dashboard
          #expect(response).to be_successful
          #expect(response.body).to match("Lead Sources")
        #end

        #it "displays a link to Property Management" do
          #get :dashboard
          #expect(response).to be_successful
          #expect(response.body).to match("Properties")
        #end

        #it "displays a link to Lead Management" do
          #get :dashboard
          #expect(response).to be_successful
          #expect(response.body).to match("Create Lead")
        #end
      #end

    #end

    #describe "as an agent" do
      #before do
        #sign_in agent
      #end

      #describe "the navigation bar" do
        #it "displays a link to User Management" do
          #get :dashboard
          #expect(response).to be_successful
          #expect(response.body).to match("Manage Bluesky Users")
        #end

        #it "does not display a link to Role Management" do
          #get :dashboard
          #expect(response).to be_successful
          #expect(response.body).to_not match("Manage User Roles")
        #end

        #it "does not display a link to LeadSource Management" do
          #get :dashboard
          #expect(response).to be_successful
          #expect(response.body).to_not match("Lead Sources")
        #end

        #it "displays a link to Property Management" do
          #get :dashboard
          #expect(response).to be_successful
          #expect(response.body).to match("Properties")
        #end

        #it "displays a link to Lead Management" do
          #get :dashboard
          #expect(response).to be_successful
          #expect(response.body).to match("Create Lead")
        #end

        #it "displays a section for System" do
          #get :dashboard
          #expect(response).to be_successful
          #expect(response.body).to match("System")
        #end
      #end

    #end

    describe "as a manager" do
      before do
        sign_in manager
      end

      describe "GET #dashboard" do
        it "renders succesfully" do
          get :dashboard
          expect(response).to be_successful
        end
      end

      describe "GET #manager_dashboard" do
        it "is successful" do
          get :manager_dashboard
          expect(response).to be_successful
        end
      end
    end

  end

  describe "impersonation" do
    describe "as an administrator" do
      describe "POST home/impersonate" do
        it "should set current_user to the impersonated user" do
          sign_in administrator
          post :impersonate, params: {id: agent.id}
          expect(response).to be_redirect
          expect(assigns[:current_user]).to eq(agent)
          expect(assigns[:true_current_user]).to eq(administrator)
        end

        it "should set true_current_user to the original identity" do
          sign_in administrator
          post :impersonate, params: {id: agent.id}
          expect(response).to be_redirect
          expect(assigns[:true_current_user]).to eq(administrator)
        end

        it "should load subsequent pages as the impersonated user" do
          sign_in administrator
          post :impersonate, params: {id: agent.id}
          expect(response).to be_redirect
          get :dashboard
          expect(assigns[:current_user]).to eq(agent)
        end

        it "should indicate in the footer that a user is being impersonated" do
          sign_in administrator
          post :impersonate, params: {id: agent.id}
          expect(response).to be_redirect
          get :dashboard
          expect(assigns[:current_user]).to eq(agent)
          expect(response.body).to match(/Impersonating/)
        end
      end

      describe "POST home/end_impersonation" do
        it "should end impersonation and switch back to the original identity" do
          sign_in administrator
          post :impersonate, params: {id: agent.id}
          expect(response).to be_redirect
          get :dashboard
          expect(assigns[:current_user]).to eq(agent)
          expect(assigns[:true_current_user]).to eq(administrator)
          post :end_impersonation
          expect(response).to be_redirect
          expect(assigns[:current_user]).to be_nil
          expect(assigns[:true_current_user]).to be_nil
          expect(response.body).to_not match("Impersonating")
        end

      end
    end

    describe "as a corporate user" do
      describe "POST home/impersonate" do
        it "should not allow impersonation" do
          sign_in corporate
          post :impersonate, params: {id: agent.id}
          expect(response).to be_redirect
          get :dashboard
          expect(assigns[:current_user]).to eq(corporate)
        end
      end
    end

    describe "as a manager user" do
      describe "POST home/impersonate" do
        it "should not allow impersonation" do
          sign_in manager
          post :impersonate, params: {id: agent.id}
          expect(response).to be_redirect
          get :dashboard
          expect(assigns[:current_user]).to eq(manager)
        end
      end
    end

    describe "as an agent user" do
      describe "POST home/impersonate" do
        it "should not allow impersonation" do
          sign_in agent
          post :impersonate, params: {id: agent2.id}
          expect(response).to be_redirect
          get :dashboard
          expect(assigns[:current_user]).to eq(agent)
        end
      end
    end
  end # Impersonation

  describe "a lead managing messaging preferences" do
    let(:lead) { create(:lead, user: agent, property: agent.property, state: 'open') }

    describe "displaying the message preferences page" do
      it "should be successful" do
        get :messaging_preferences, params: {id: lead.id}
        expect(response).to be_successful
      end
    end

    describe "opting out of email messaging" do
      it "should be successful" do
        refute(lead.optout_email?)
        post :unsubscribe, params: {lead_id: lead.id, lead_email_optout: true}
        expect(response).to be_successful
        lead.reload
        assert(lead.optout_email?)
      end
    end

    describe "opting into email messaging" do
      it "should be successful" do
        lead.optout_email!
        lead.save
        assert(lead.optout_email?)
        post :unsubscribe, params: {lead_id: lead.id, lead_email_optout: false}
        expect(response).to be_successful
        lead.reload
        refute(lead.optout_email?)
      end
    end

    describe "opting into sms messaging" do
      it "should be successful" do
        lead.optout_sms!
        lead.save
        assert(lead.optout_sms?)
        post :unsubscribe, params: {lead_id: lead.id, lead_sms_optout: false}
        expect(response).to be_successful
        lead.reload
        refute(lead.optout_sms?)
      end
    end

    describe "opting out of sms messaging" do
      it "should be successful" do
        lead.optin_sms!
        lead.save
        refute(lead.optout_sms?)
        post :unsubscribe, params: {lead_id: lead.id, lead_sms_optout: true}
        expect(response).to be_successful
        lead.reload
        assert(lead.optout_sms?)
      end
    end

  end

  describe "inserting an incoming lead on the dashboard page" do
    it "should be successful" do
      lead = create(:lead, property: agent.property, state: 'open')
      sign_in agent
      get :insert_unclaimed_lead, params: {id: lead.id}, xhr: true
      expect(response).to be_successful
    end

  end

end

