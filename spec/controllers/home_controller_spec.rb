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
      sign_in unroled_user
      get :dashboard
      expect(response).to be_redirect
      #expect(response).to render_template(:dashboard)
    end

    describe "as an administrator" do
      before do
        sign_in administrator
      end

      describe "the navigation bar" do
        it "displays a link to User Management" do
          get :dashboard
          expect(response).to be_successful
          expect(response.body).to match("Manage BlueSky Users")
        end

        it "displays a link to Role Management" do
          get :dashboard
          expect(response).to be_successful
          expect(response.body).to match("Manage User Roles")
        end

        it "displays a link to LeadSource Management" do
          get :dashboard
          expect(response).to be_successful
          expect(response.body).to match("Lead Sources")
        end

        it "displays a link to Property Management" do
          get :dashboard
          expect(response).to be_successful
          expect(response.body).to match("Properties")
        end

        it "displays a link to Lead Management" do
          get :dashboard
          expect(response).to be_successful
          expect(response.body).to match("Create Lead")
        end
      end
    end

    describe "as an corporate" do
      before do
        sign_in corporate
      end

      describe "the navigation bar" do
        it "displays a link to User Management" do
          get :dashboard
          expect(response).to be_successful
          expect(response.body).to match("Manage BlueSky Users")
        end

        it "does not display a link to Role Management" do
          get :dashboard
          expect(response).to be_successful
          expect(response.body).to_not match("Manage User Roles")
        end

        it "displays a link to LeadSource Management" do
          get :dashboard
          expect(response).to be_successful
          expect(response.body).to match("Lead Sources")
        end

        it "displays a link to Property Management" do
          get :dashboard
          expect(response).to be_successful
          expect(response.body).to match("Properties")
        end

        it "displays a link to Lead Management" do
          get :dashboard
          expect(response).to be_successful
          expect(response.body).to match("Create Lead")
        end
      end

    end

    describe "as an agent" do
      before do
        sign_in agent
      end

      describe "the navigation bar" do
        it "displays a link to User Management" do
          get :dashboard
          expect(response).to be_successful
          expect(response.body).to match("Manage BlueSky Users")
        end

        it "does not display a link to Role Management" do
          get :dashboard
          expect(response).to be_successful
          expect(response.body).to_not match("Manage User Roles")
        end

        it "does not display a link to LeadSource Management" do
          get :dashboard
          expect(response).to be_successful
          expect(response.body).to_not match("Lead Sources")
        end

        it "displays a link to Property Management" do
          get :dashboard
          expect(response).to be_successful
          expect(response.body).to match("Properties")
        end

        it "displays a link to Lead Management" do
          get :dashboard
          expect(response).to be_successful
          expect(response.body).to match("Create Lead")
        end

        it "displays a section for System" do
          get :dashboard
          expect(response).to be_successful
          expect(response.body).to match("System")
        end
      end

    end

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
    end

  end

end

