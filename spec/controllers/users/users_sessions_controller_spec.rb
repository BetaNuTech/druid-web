require 'rails_helper'

RSpec.describe Users::SessionsController, type: :controller do
  include_context "users"
  render_views

  let(:user_pw) { 'Foobar123' }

  before do
   @request.env["devise.mapping"] = Devise.mappings[:user]
   unroled_user.password = unroled_user.password_confirmation = user_pw
   unroled_user.save!
  end

  describe "when a user is unauthenticated" do
    let(:user_attributes) { attributes_for(:user) }

    describe "visiting a privileged page" do
      before do
        @controller = LeadsController.new
      end

      it "redirects to the login page" do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe "visiting the login page" do
      it "allows logging in with valid credentials" do
        post :create, params: {user: {email: unroled_user.email, password: user_pw}}
        expect(response).to redirect_to(authenticated_root_path)
        expect(session["flash"]["flashes"]["notice"]).to eq('Signed in successfully.')
      end

      it "will not authenticate with invalid credentials" do
        post :create, params: {user: {email: unroled_user.email, password: 'wrong password' }}
        expect(response).to be_successful
        expect(session).to be_empty
      end
    end
  end


end
