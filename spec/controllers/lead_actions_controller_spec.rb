require 'rails_helper'

RSpec.describe LeadActionsController, type: :controller do
  include_context "users"
  render_views

  let(:valid_attributes) { attributes_for(:lead_action) }
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
        expect(response).to be_successful
      end
    end

    describe "as an corporate" do
      it "should succeed" do
        sign_in corporate
        get :index
        expect(response).to be_successful
      end
    end

    describe "as an administrator" do
      it "should succeed" do
        sign_in administrator
        get :index
        expect(response).to be_successful
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

    describe "as an corporate" do
      it "should succeed" do
        sign_in corporate
        get :new
        expect(response).to be_successful
      end
    end

    describe "as an administrator" do
      it "should succeed" do
        sign_in administrator
        get :new
        expect(response).to be_successful
      end

      it "should default to active" do
        sign_in administrator
        get :new
        assert assigns(:lead_action).active
      end
    end
  end

  describe "POST #create" do
    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        post :create, params: {lead_action: valid_attributes}
        expect(response).to be_redirect
      end

      it "should not create a LeadAction" do
        expect{
          post :create, params: {lead_action: valid_attributes}
        }.to_not change{LeadAction.count}
      end
    end

    describe "as a unroled user" do
      before do
        sign_in unroled_user
      end

      it "should fail and redirect" do
        post :create, params: {lead_action: valid_attributes}
        expect(response).to be_redirect
      end

      it "should not create a LeadAction" do
        expect{
          post :create, params: {lead_action: valid_attributes}
        }.to_not change{LeadAction.count}
      end

    end

    describe "as an agent" do
      before do
        sign_in agent
      end

      it "should fail and redirect" do
        post :create, params: {lead_action: valid_attributes}
        expect(response).to be_redirect
      end

      it "should not create a LeadAction" do
        expect{
          post :create, params: {lead_action: valid_attributes}
        }.to_not change{LeadAction.count}
      end
    end

    describe "as an corporate" do
      before do
        sign_in corporate
      end

      it "should create a LeadAction with valid attributes" do
        expect{
          post :create, params: {lead_action: valid_attributes}
        }.to change{LeadAction.count}.by(1)
        post :create, params: {lead_action: valid_attributes}
        expect(response).to be_successful
      end
    end

    describe "as an administrator" do
      before do
        sign_in administrator
      end

      it "should create a LeadAction with valid attributes" do
        expect{
          post :create, params: {lead_action: valid_attributes}
        }.to change{LeadAction.count}.by(1)
        post :create, params: {lead_action: valid_attributes}
        expect(response).to be_successful
      end

      it "should handle invalid attributes" do
        post :create, params: {lead_action: invalid_attributes}
        expect(response).to be_successful
        expect {
          post :create, params: {lead_action: invalid_attributes}
        }.to_not change{LeadAction.count}
      end
    end
  end

  describe "GET #show" do
    let(:lead_action) { create(:lead_action) }

    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        get :show, params: {id: lead_action.id}
        expect(response).to be_redirect
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        sign_in unroled_user
        get :show, params: {id: lead_action.id}
        expect(response).to be_redirect
      end
    end

    describe "as an agent" do
      it "should succeed" do
        sign_in agent
        get :show, params: {id: lead_action.id}
        expect(response).to be_successful
      end
    end

    describe "as an corporate" do
      it "should succeed" do
        sign_in corporate
        get :show, params: {id: lead_action.id}
        expect(response).to be_successful
      end
    end

    describe "as an administrator" do
      it "should succeed" do
        sign_in administrator
        get :show, params: {id: lead_action.id}
        expect(response).to be_successful
      end
    end
  end

  describe "GET #edit" do

    let(:lead_action) { create(:lead_action) }

    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        get :edit, params: {id: lead_action.id}
        expect(response).to be_redirect
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        sign_in unroled_user
        get :edit, params: {id: lead_action.id}
        expect(response).to be_redirect
      end
    end

    describe "as an agent" do
      it "should fail and redirect" do
        sign_in agent
        get :edit, params: {id: lead_action.id}
        expect(response).to be_redirect
      end
    end

    describe "as an corporate" do
      it "should succeed" do
        sign_in corporate
        get :edit, params: {id: lead_action.id}
        expect(response).to be_successful
      end
    end

    describe "as an administrator" do
      it "should succeed" do
        sign_in administrator
        get :edit, params: {id: lead_action.id}
        expect(response).to be_successful
      end
    end
  end

  describe "PUT #update" do
    let(:lead_action) { create(:lead_action) }
    let(:updated_attributes) { {name: 'foobar12'}}
    let(:invalid_updated_attributes) {
      # Attributes with a duplicate name
      old_lead_action = create(:lead_action)
      {name: old_lead_action.name}
    }

    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        expect{
          put :update, params: {id: lead_action.id, lead_action: updated_attributes}
          expect(response).to be_redirect
          lead_action.reload
        }.to_not change{lead_action.name}
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        sign_in unroled_user
        expect{
          put :update, params: {id: lead_action.id, lead_action: updated_attributes}
          expect(response).to be_redirect
          lead_action.reload
        }.to_not change{lead_action.name}
      end
    end

    describe "as an agent" do
      it "should fail and redirect" do
        sign_in agent
        expect{
          put :update, params: {id: lead_action.id, lead_action: updated_attributes}
          expect(response).to be_redirect
          lead_action.reload
        }.to_not change{lead_action.name}
      end
    end

    describe "as an corporate" do
      it "should succeed" do
        sign_in corporate
        expect{
          put :update, params: {id: lead_action.id, lead_action: updated_attributes}
          expect(response).to be_redirect
          lead_action.reload
        }.to change{lead_action.name}
      end
    end

    describe "as an administrator" do
      before do
        lead_action
        sign_in administrator
      end

      it "should succeed" do
        expect{
          put :update, params: {id: lead_action.id, lead_action: updated_attributes}
          expect(response).to be_redirect
          lead_action.reload
        }.to change{lead_action.name}
      end

      it "should handle invalid attributes" do
        expect{
          put :update, params: {id: lead_action.id, lead_action: invalid_updated_attributes}
          expect(response).to be_successful
          lead_action.reload
        }.to_not change{lead_action.name}
      end
    end
  end

  describe "DELETE #destroy" do

    let(:lead_action) { create(:lead_action) }

    before do
      lead_action
    end

    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        expect {
          delete :destroy, params: {id: lead_action.id}
          expect(response).to be_redirect
        }.to_not change{LeadAction.count}
      end
    end

    describe "as an unroled user" do
      it "should fail and redirect" do
        sign_in unroled_user
        expect {
          delete :destroy, params: {id: lead_action.id}
          expect(response).to be_redirect
        }.to_not change{LeadAction.count}
      end
    end

    describe "as an agent" do
      it "should fail and redirect" do
        sign_in agent
        expect {
          delete :destroy, params: {id: lead_action.id}
          expect(response).to be_redirect
        }.to_not change{LeadAction.count}
      end
    end

    describe "as an corporate" do
      it "should succeed" do
        sign_in corporate
        expect {
          delete :destroy, params: {id: lead_action.id}
          expect(response).to be_redirect
        }.to change{LeadAction.count}.by(-1)
      end
    end

    describe "as an administrator" do
      it "should succeed" do
        sign_in administrator
        expect {
          delete :destroy, params: {id: lead_action.id}
          expect(response).to be_redirect
        }.to change{LeadAction.count}.by(-1)
      end
    end
  end

end
