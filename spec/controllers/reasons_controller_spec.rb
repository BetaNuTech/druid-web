require 'rails_helper'

RSpec.describe ReasonsController, type: :controller do
  include_context "users"
  render_views

  let(:valid_attributes) { attributes_for(:reason) }
  let(:invalid_attributes) { {description: 'foobar'}}

  describe "GET #index" do
    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        get :index
        expect(response).to be_redirect
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        sign_in unroled_user
        get :index
        expect(response).to be_redirect
      end
    end

    describe "as an agent" do
      it "should succeed" do
        sign_in agent
        get :index
        expect(response).to be_success
      end
    end

    describe "as an operator" do
      it "should succeed" do
        sign_in operator
        get :index
        expect(response).to be_success
      end
    end

    describe "as an administrator" do
      it "should succeed" do
        sign_in administrator
        get :index
        expect(response).to be_success
      end
    end

  end

  describe "GET #new" do
    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        get :new
        expect(response).to be_redirect
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        sign_in unroled_user
        get :new
        expect(response).to be_redirect
      end
    end

    describe "as an agent" do
      it "should fail and redirect" do
        sign_in agent
        get :new
        expect(response).to be_redirect
      end
    end

    describe "as an operator" do
      it "should succeed" do
        sign_in operator
        get :new
        expect(response).to be_success
      end
    end

    describe "as an administrator" do
      it "should succeed" do
        sign_in administrator
        get :new
        expect(response).to be_success
      end
    end
  end

  describe "POST #create" do
    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        post :create, params: {reason: valid_attributes}
        expect(response).to be_redirect
      end

      it "should not create a Reason" do
        expect{
          post :create, params: {reason: valid_attributes}
        }.to_not change{Reason.count}
      end
    end

    describe "as a unroled user" do
      before do
        sign_in unroled_user
      end

      it "should fail and redirect" do
        post :create, params: {reason: valid_attributes}
        expect(response).to be_redirect
      end

      it "should not create a Reason" do
        expect{
          post :create, params: {reason: valid_attributes}
        }.to_not change{Reason.count}
      end

    end

    describe "as an agent" do
      before do
        sign_in agent
      end

      it "should fail and redirect" do
        post :create, params: {reason: valid_attributes}
        expect(response).to be_redirect
      end

      it "should not create a Reason" do
        expect{
          post :create, params: {reason: valid_attributes}
        }.to_not change{Reason.count}
      end
    end

    describe "as an operator" do
      before do
        sign_in operator
      end

      it "should create a Reason with valid attributes" do
        expect{
          post :create, params: {reason: valid_attributes}
        }.to change{Reason.count}.by(1)
        post :create, params: {reason: valid_attributes}
        expect(response).to be_success
      end
    end

    describe "as an administrator" do
      before do
        sign_in administrator
      end

      it "should create a Reason with valid attributes" do
        expect{
          post :create, params: {reason: valid_attributes}
        }.to change{Reason.count}.by(1)
        post :create, params: {reason: valid_attributes}
        expect(response).to be_success
      end

      it "should handle invalid attributes" do
        post :create, params: {reason: invalid_attributes}
        expect(response).to be_success
        expect {
          post :create, params: {reason: invalid_attributes}
        }.to_not change{Reason.count}
      end
    end
  end

  describe "GET #show" do
    let(:reason) { create(:reason) }

    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        get :show, params: {id: reason.id}
        expect(response).to be_redirect
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        sign_in unroled_user
        get :show, params: {id: reason.id}
        expect(response).to be_redirect
      end
    end

    describe "as an agent" do
      it "should succeed" do
        sign_in agent
        get :show, params: {id: reason.id}
        expect(response).to be_success
      end
    end

    describe "as an operator" do
      it "should succeed" do
        sign_in operator
        get :show, params: {id: reason.id}
        expect(response).to be_success
      end
    end

    describe "as an administrator" do
      it "should succeed" do
        sign_in administrator
        get :show, params: {id: reason.id}
        expect(response).to be_success
      end
    end
  end

  describe "GET #edit" do

    let(:reason) { create(:reason) }

    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        get :edit, params: {id: reason.id}
        expect(response).to be_redirect
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        sign_in unroled_user
        get :edit, params: {id: reason.id}
        expect(response).to be_redirect
      end
    end

    describe "as an agent" do
      it "should fail and redirect" do
        sign_in agent
        get :edit, params: {id: reason.id}
        expect(response).to be_redirect
      end
    end

    describe "as an operator" do
      it "should succeed" do
        sign_in operator
        get :edit, params: {id: reason.id}
        expect(response).to be_success
      end
    end

    describe "as an administrator" do
      it "should succeed" do
        sign_in administrator
        get :edit, params: {id: reason.id}
        expect(response).to be_success
      end
    end
  end

  describe "PUT #update" do
    let(:reason) { create(:reason) }
    let(:updated_attributes) { {name: 'foobar12'}}
    let(:invalid_updated_attributes) {
      # Attributes with a duplicate name
      old_reason = create(:reason)
      {name: old_reason.name}
    }

    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        expect{
          put :update, params: {id: reason.id, reason: updated_attributes}
          expect(response).to be_redirect
          reason.reload
        }.to_not change{reason.name}
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        sign_in unroled_user
        expect{
          put :update, params: {id: reason.id, reason: updated_attributes}
          expect(response).to be_redirect
          reason.reload
        }.to_not change{reason.name}
      end
    end

    describe "as an agent" do
      it "should fail and redirect" do
        sign_in agent
        expect{
          put :update, params: {id: reason.id, reason: updated_attributes}
          expect(response).to be_redirect
          reason.reload
        }.to_not change{reason.name}
      end
    end

    describe "as an operator" do
      it "should succeed" do
        sign_in operator
        expect{
          put :update, params: {id: reason.id, reason: updated_attributes}
          expect(response).to be_redirect
          reason.reload
        }.to change{reason.name}
      end
    end

    describe "as an administrator" do
      before do
        reason
        sign_in administrator
      end

      it "should succeed" do
        expect{
          put :update, params: {id: reason.id, reason: updated_attributes}
          expect(response).to be_redirect
          reason.reload
        }.to change{reason.name}
      end

      it "should handle invalid attributes" do
        expect{
          put :update, params: {id: reason.id, reason: invalid_updated_attributes}
          expect(response).to be_success
          reason.reload
        }.to_not change{reason.name}
      end
    end
  end

  describe "DELETE #destroy" do

    let(:reason) { create(:reason) }

    before do
      reason
    end

    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        expect {
          delete :destroy, params: {id: reason.id}
          expect(response).to be_redirect
        }.to_not change{Reason.count}
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        sign_in unroled_user
        expect {
          delete :destroy, params: {id: reason.id}
          expect(response).to be_redirect
        }.to_not change{Reason.count}
      end
    end

    describe "as an agent" do
      it "should fail and redirect" do
        sign_in agent
        expect {
          delete :destroy, params: {id: reason.id}
          expect(response).to be_redirect
        }.to_not change{Reason.count}
      end
    end

    describe "as an operator" do
      it "should succeed" do
        sign_in operator
        expect {
          delete :destroy, params: {id: reason.id}
          expect(response).to be_redirect
        }.to change{Reason.count}.by(-1)
      end
    end

    describe "as an administrator" do
      it "should succeed" do
        sign_in administrator
        expect {
          delete :destroy, params: {id: reason.id}
          expect(response).to be_redirect
        }.to change{Reason.count}.by(-1)
      end
    end
  end

end
