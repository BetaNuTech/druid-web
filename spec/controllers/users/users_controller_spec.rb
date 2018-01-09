require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  include_context "users"
  render_views

  # This should return the minimal set of attributes required to create a valid
  # User. As you add validations to User, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    attributes_for(:user)
  }

  let(:invalid_attributes) {
    {
      email: 'invalid_email'
    }
  }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # UsersController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  describe "GET #index" do
    it "returns a success response" do
      sign_in unroled_user
      user = User.create! valid_attributes
      get :index, params: {}
      expect(response).to be_success
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      sign_in unroled_user
      user = User.create! valid_attributes
      get :show, params: {id: user.to_param}
      expect(response).to be_success
    end
  end

  describe "GET #new" do
    it "returns a success response" do
      sign_in unroled_user
      get :new, params: {}
      expect(response).to be_success
    end
  end

  describe "GET #edit" do
    it "returns a success response" do
      sign_in unroled_user
      user = User.create! valid_attributes
      get :edit, params: {id: user.to_param}
      expect(response).to be_success
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new User" do
        sign_in unroled_user
        expect {
          post :create, params: {user: valid_attributes}
        }.to change(User, :count).by(1)
      end

      it "redirects to the created user" do
        sign_in unroled_user
        post :create, params: {user: valid_attributes}
        new_user = User.where(email: valid_attributes[:email]).order("created_at desc").last
        expect(response).to redirect_to(new_user)
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'new' template)" do
        sign_in unroled_user
        post :create, params: {user: invalid_attributes}
        expect(response).to be_success
      end
    end
  end

  describe "PUT #update" do
    context "with valid params" do
      let(:new_attributes) {
        pw = 'Foobar123.'
        {
          password: pw,
          password_confirmation: pw
        }
      }

      it "updates the requested user" do
        sign_in unroled_user
        user = User.create! valid_attributes
        old_pw = user.encrypted_password
        put :update, params: {id: user.to_param, user: new_attributes}
        user.reload
        expect(user.encrypted_password).to_not eq(old_pw)
      end

      it "redirects to the user" do
        sign_in unroled_user
        user = User.create! valid_attributes
        put :update, params: {id: user.to_param, user: valid_attributes}
        expect(response).to redirect_to(user)
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'edit' template)" do
        sign_in unroled_user
        user = User.create! valid_attributes
        put :update, params: {id: user.to_param, user: invalid_attributes}
        expect(response).to be_success
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested user" do
      sign_in unroled_user
      user = User.create! valid_attributes
      expect {
        delete :destroy, params: {id: user.to_param}
      }.to change(User, :count).by(-1)
    end

    it "redirects to the users list" do
      sign_in unroled_user
      user = User.create! valid_attributes
      delete :destroy, params: {id: user.to_param}
      expect(response).to redirect_to(users_url)
    end
  end

end
