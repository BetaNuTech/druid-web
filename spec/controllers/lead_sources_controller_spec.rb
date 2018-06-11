require 'rails_helper'

RSpec.describe LeadSourcesController, type: :controller do
  include_context "users"
  render_views

  let(:valid_attributes) {
    attributes_for(:lead_source)
  }

  let(:invalid_attributes) {
    {name: 'foo'}
  }

  let(:valid_session) { {} }

  describe "GET #index" do
    include_examples "authenticated action", {params: {}, name: 'index'}

    describe "as an administrator" do
      it "allows access" do
        sign_in administrator
        get :index, params: {}, session: valid_session, format: 'html'
        expect(response).to be_successful
      end
    end

    describe "as an operator" do
      [:html, :json].each do |format|
        it "as #{format}: returns a success response when no records are present" do
          sign_in operator
          get :index, params: {}, session: valid_session, format: format
          expect(response).to be_successful
        end

        it "as #{format}: returns a success response when records are present" do
          sign_in operator
          create(:lead_source)
          get :index, params: {}, session: valid_session, format: format
          expect(response).to be_successful
        end
      end
    end

    describe "as an agent" do
      it "denies access" do
        sign_in agent
        get :index, params: {}, session: valid_session, format: 'html'
        expect(response).to be_redirect
      end
    end
  end

  describe "GET #new" do
    include_examples "authenticated action", {params: {}, name: 'new'}

    describe "as an operator" do
      it "returns a success response" do
        sign_in operator
        get :new, params: {}, session: valid_session
        expect(response).to be_successful
      end
    end

    describe "as an agent" do
      it "denies access" do
        sign_in agent
        get :index, params: {}, session: valid_session, format: 'html'
        expect(response).to be_redirect
      end
    end
  end

  describe "GET #show" do
    describe "as an operator" do
      it "returns a success response" do
        sign_in operator
        lead_source = create(:lead_source)
        get :show, params: { id: lead_source.to_param}, session: valid_session
        expect(response).to be_successful
      end
    end

    describe "an an agent" do
      it "denies access" do
        sign_in agent
        lead_source = create(:lead_source)
        get :show, params: { id: lead_source.to_param}, session: valid_session
        expect(response).to be_redirect
      end
    end

  end

  describe "GET #edit" do
    include_examples "authenticated action", {params: {}, name: 'new'}

    describe "as an operator" do
      it "returns a success response" do
        sign_in operator
        lead_source = create(:lead_source)
        get :edit, params: { id: lead_source.to_param}, session: valid_session
        expect(response).to be_successful
      end
    end

    describe "an an agent" do
      it "denies access" do
        sign_in agent
        lead_source = create(:lead_source)
        get :edit, params: { id: lead_source.to_param}, session: valid_session
        expect(response).to be_redirect
      end
    end

  end

  describe "POST #create" do
    describe "as an operator" do
      context "with valid params" do
        it "creates a new lead source" do
          sign_in operator
          expect{
            post :create, params: {lead_source: valid_attributes}, session: valid_session
          }.to change(LeadSource, :count).by(1)
        end

        it "redirects to the created lead" do
          sign_in operator
          post :create, params: {lead_source: valid_attributes}, session: valid_session
          expect(response).to redirect_to(LeadSource.last)
        end
      end

      context "with invalid params" do
        it "does not create a new lead source" do
          sign_in operator
          expect{
            post :create, params: {lead_source: invalid_attributes}, session: valid_session
          }.to change(LeadSource, :count).by(0)
        end

        it "returns a success response (i.e. to display the 'new' template)" do
          sign_in operator
          post :create, params: {lead_source: invalid_attributes}, session: valid_session
          expect(response).to be_successful
        end
      end
    end

    describe "as an agent" do
      context "with valid params" do
        it "does not create a new lead source" do
          sign_in agent
          expect{
            post :create, params: {lead_source: valid_attributes}, session: valid_session
          }.to change(LeadSource, :count).by(0)
        end
      end
    end

  end

  describe "PUT #update" do
    let(:new_attributes) {
      {name: 'foobar12'}
    }

    let(:invalid_attributes) {
      {name: ''}
    }

    describe "as an administrator" do
      context "with valid params" do
        it "updates the requested lead source" do
          sign_in administrator
          lead_source = create(:lead_source)
          put :update, params: {id: lead_source.to_param, lead_source: new_attributes}, session: valid_session
          lead_source.reload
          expect(lead_source.name).to eq(new_attributes[:name])
        end
      end
    end

    describe "as an operator" do

      context "with valid params" do
        it "updates the requested lead source" do
          sign_in operator
          lead_source = create(:lead_source)
          put :update, params: {id: lead_source.to_param, lead_source: new_attributes}, session: valid_session
          lead_source.reload
          expect(lead_source.name).to eq(new_attributes[:name])
        end

        it "redirects to the lead source" do
          sign_in operator
          lead_source = create(:lead_source)
          put :update, params: {id: lead_source.to_param, lead_source: new_attributes}, session: valid_session
          expect(response).to redirect_to(lead_source)
        end
      end

      context "with invalid params" do
        it "returns a success response (i.e. to display the 'edit' template)" do
          sign_in operator
          lead_source = create(:lead_source)
          put :update, params: {id: lead_source.to_param, lead_source: invalid_attributes}, session: valid_session
          expect(response).to be_successful
        end
      end
    end

    describe "as an agent" do
      it "does not update the requested lead source" do
        sign_in agent
        lead_source = create(:lead_source)
        put :update, params: {id: lead_source.to_param, lead_source: new_attributes}, session: valid_session
        lead_source.reload
        expect(lead_source.name).to_not eq(new_attributes[:name])
      end
    end

  end

  describe "DELETE #destroy" do
    describe "as an operator" do
      it "destroys the requested lead_source" do
        sign_in operator
        lead_source = create(:lead_source)
        expect {
          delete :destroy, params: {id: lead_source.to_param}, session: valid_session
        }.to change(LeadSource, :count).by(-1)
      end

      it "redirects to the lead_sources list" do
        sign_in operator
        lead_source = create(:lead_source)
        delete :destroy, params: {id: lead_source.to_param}, session: valid_session
        expect(response).to redirect_to(lead_sources_url)
      end
    end

    describe "as an agent" do
      it "does not destroy the requested lead_source" do
        sign_in agent
        lead_source = create(:lead_source)
        expect {
          delete :destroy, params: {id: lead_source.to_param}, session: valid_session
        }.to change(LeadSource, :count).by(0)
      end
    end
  end

  describe "POST #reset_token" do
    describe "as an operator" do
      [:html, :json].each do |format|
        it "should reset the api token via a #{format} request" do
          sign_in operator
          lead_source = create(:lead_source)
          expect{
            post :reset_token, params: {id: lead_source.to_param}, format: format
            lead_source.reload
          }.to change(lead_source, :api_token)
        end
      end
    end

    describe "as an agent" do
      it "does not modify the api token" do
        sign_in agent
        lead_source = create(:lead_source)
        expect{
          post :reset_token, params: {id: lead_source.to_param}, format: 'html'
          lead_source.reload
        }.to_not change(lead_source, :api_token)
      end
    end

  end

end
