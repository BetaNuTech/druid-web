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
  end

end

