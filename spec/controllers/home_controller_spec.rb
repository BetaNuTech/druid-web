require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  include_context "users"
  render_views

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
      expect(response).to be_success
      expect(response).to render_template(:dashboard)
    end

    describe "as an administrator" do
      before do
        sign_in administrator
      end

      describe "the navigation bar" do
        it "displays a link to User Management" do
          get :dashboard
          expect(response).to be_success
          expect(response.body).to match("Manage Druid Users")
        end

        it "displays a link to Role Management" do
          get :dashboard
          expect(response).to be_success
          expect(response.body).to match("Manage User Roles")
        end

        it "displays a link to LeadSource Management" do
          get :dashboard
          expect(response).to be_success
          expect(response.body).to match("Lead Sources")
        end

        it "displays a link to Property Management" do
          get :dashboard
          expect(response).to be_success
          expect(response.body).to match("Manage Properties")
        end

        it "displays a link to Lead Management" do
          get :dashboard
          expect(response).to be_success
          expect(response.body).to match("Create Lead")
        end
      end
    end

    describe "as an operator" do
      before do
        sign_in operator
      end

      describe "the navigation bar" do
        it "displays a link to User Management" do
          get :dashboard
          expect(response).to be_success
          expect(response.body).to match("Manage Druid Users")
        end

        it "does not display a link to Role Management" do
          get :dashboard
          expect(response).to be_success
          expect(response.body).to_not match("Manage User Roles")
        end

        it "displays a link to LeadSource Management" do
          get :dashboard
          expect(response).to be_success
          expect(response.body).to match("Lead Sources")
        end

        it "displays a link to Property Management" do
          get :dashboard
          expect(response).to be_success
          expect(response.body).to match("Manage Properties")
        end

        it "displays a link to Lead Management" do
          get :dashboard
          expect(response).to be_success
          expect(response.body).to match("Create Lead")
        end
      end

    end

    describe "as an agent" do
      before do
        sign_in agent
      end

      describe "the navigation bar" do
        it "does not display a link to User Management" do
          get :dashboard
          expect(response).to be_success
          expect(response.body).to_not match("Manage Druid Users")
        end

        it "does not display a link to Role Management" do
          get :dashboard
          expect(response).to be_success
          expect(response.body).to_not match("Manage User Roles")
        end

        it "does not display a link to LeadSource Management" do
          get :dashboard
          expect(response).to be_success
          expect(response.body).to_not match("Lead Sources")
        end

        it "displays a link to Property Management" do
          get :dashboard
          expect(response).to be_success
          expect(response.body).to match("Manage Properties")
        end

        it "displays a link to Lead Management" do
          get :dashboard
          expect(response).to be_success
          expect(response.body).to match("Create Lead")
        end

        it "does not display a section for System" do
          get :dashboard
          expect(response).to be_success
          expect(response.body).to_not match("System")
        end
      end

    end

  end

end

