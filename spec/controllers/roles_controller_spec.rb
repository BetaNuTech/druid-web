require 'rails_helper'

RSpec.describe RolesController, type: :controller do
  include_context "users"
  render_views

  let(:role) { create(:role) }

  let(:valid_attributes) {
    attributes_for(:role)
  }

  let(:invalid_attributes) {
    attrs = attributes_for(:role)
    attrs[:name] = nil
    attrs
  }

  describe "GET #index" do
    include_examples "authenticated action", {params: {}, name: 'index'}

    it "returns a successful response" do
      sign_in unroled_user
      create(:role)
      get :index, params: {}
      expect(response).to be_success
    end

    it "can return JSON data" do
      sign_in unroled_user
      get :index, params: {}, format: :json
      expect(response).to be_success
    end
  end

  describe "GET #show" do
    include_examples "authenticated action", {params: {id: 0 }, name: 'show'}

    it "returns a successful response" do
      sign_in unroled_user
      get :show, params: {id: role.id}
      expect(response).to be_success
    end

    it "can return JSON data" do
      sign_in unroled_user
      get :show, params: {id: role.id}, format: :json
      expect(response).to be_success
    end
  end

  describe "GET #new" do
    include_examples "authenticated action", {params: {}, name: 'new'}

    it "returns a successful response" do
      sign_in unroled_user
      get :new, params: {}
      expect(response).to be_success
    end
  end

  describe "GET #edit" do
    include_examples "authenticated action", {params: {id: 0}, name: 'edit'}

    it "returns a successful response" do
      sign_in unroled_user
      get :edit, params: {id: role.id}
      expect(response).to be_success
    end
  end

  describe "POST #create" do

    describe "with an unauthenticated user" do

      it "should redirect to login" do
        post :create, params: { role: valid_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end

      it "should make no change" do
        expect {
          post :create, params: { role: valid_attributes }
        }.to change{ Role.count }.by(0)
      end
    end

    describe "with an authenticated user" do
      describe "with valid attributes" do
        it "should create the record" do
          sign_in unroled_user
          expect {
            post :create, params: {role: valid_attributes}
          }.to change{Role.count}.by(1)
        end

        it "should redirect to #show" do
          sign_in unroled_user
          post :create, params: {role: valid_attributes}
          expect(response).to redirect_to(role_path(Role.last))
        end
      end

      describe "with invalid attributes" do
        it "should not create a record" do
          sign_in unroled_user
          expect {
            post :create, params: {role: invalid_attributes}
          }.to change{Role.count}.by(0)
        end

        it "should re-render the page" do
          sign_in unroled_user
          post :create, params: {role: invalid_attributes}
          expect(response).to be_success
        end
      end
    end

  end

  describe "PUT #update" do
    let(:new_name) { 'Foobar' }

    describe "with an unauthenticated user" do
      it "should not change the record" do
        role
        expect {
          put :update, params: {id: role.id, role: {name: new_name}}
          role.reload
        }.to_not change{role.name}
      end

      it "should redirect to login" do
        put :update, params: {id: role.id, role: {name: new_name}}
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe "with an authenticated user" do
      describe "with invalid attributes" do
        it "should not update the record" do
          role
          sign_in unroled_user
          expect {
            put :update, params: {id: role.id, role: {name: ''}}
          }.to_not change{role.name}
        end

        it "should re-render the form" do
          role
          sign_in unroled_user
          put :update, params: {id: role.id, role: {name: ''}}
          expect(response).to be_success
        end
      end

      describe "with valid attributes" do
        it "should update the record" do
          role
          sign_in unroled_user
          expect {
            put :update, params: {id: role.id, role: {name: new_name}}
            role.reload
          }.to change{role.name}
        end

        it "should redirect to #show" do
          role
          sign_in unroled_user
          put :update, params: {id: role.id, role: {name: new_name}}
          expect(response).to redirect_to(role_path(role))
        end
      end
    end
  end

  describe "DELETE #destroy" do
    before do
      role
    end

    describe "with an unuauthenticated user" do
      it "should not delete the record" do
        expect{
          delete :destroy, params: {id: role.id}
        }.to change{Role.count}.by(0)
      end
    end

    describe "with an authenticated user" do
      it "should delete the record" do
        sign_in unroled_user
        expect{
          delete :destroy, params: {id: role.id}
        }.to change{Role.count}.by(-1)

      end

      it "should redirect to #index" do
        sign_in unroled_user
        delete :destroy, params: {id: role.id}
        expect(response).to redirect_to(roles_path)
      end
    end

  end

end
