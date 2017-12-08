require 'rails_helper'

RSpec.describe LeadSourcesController, type: :controller do
  render_views

  let(:valid_attributes) {
    attributes_for(:lead_source)
  }

  let(:invalid_attributes) {
    {name: 'foo'}
  }

  let(:valid_session) { {} }

  describe "GET #index" do
    [:html, :json].each do |format|
      it "as #{format}: returns a success response when no records are present" do
        get :index, params: {}, session: valid_session, format: format
        expect(response).to be_success
      end

      it "as #{format}: returns a success response when records are present" do
        create(:lead_source)
        get :index, params: {}, session: valid_session, format: format
        expect(response).to be_success
      end
    end
  end

  describe "GET #new" do
    it "returns a success response" do
      get :new, params: {}, session: valid_session
      expect(response).to be_success
    end
  end

  describe "GET #edit" do
    it "returns a success response" do
      lead_source = create(:lead_source)
      get :edit, params: { id: lead_source.to_param}, session: valid_session
      expect(response).to be_success
    end
  end

  describe "POST #create" do
    context "with valid params" do
      it "creates a new lead source" do
        expect{
          post :create, params: {lead_source: valid_attributes}, session: valid_session
        }.to change(LeadSource, :count).by(1)
      end
      it "redirects to the created lead" do
        post :create, params: {lead_source: valid_attributes}, session: valid_session
        expect(response).to redirect_to(LeadSource.last)
      end
    end

    context "with invalid params" do
      it "does not create a new lead source" do
        expect{
          post :create, params: {lead_source: invalid_attributes}, session: valid_session
        }.to change(LeadSource, :count).by(0)
      end
      it "returns a success response (i.e. to display the 'new' template)" do
        post :create, params: {lead_source: invalid_attributes}, session: valid_session
        expect(response).to be_success
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


    context "with valid params" do
      it "updates the requested lead source" do
        lead_source = create(:lead_source)
        put :update, params: {id: lead_source.to_param, lead_source: new_attributes}, session: valid_session
        lead_source.reload
        expect(lead_source.name).to eq(new_attributes[:name])
      end

      it "redirects to the lead source" do
        lead_source = create(:lead_source)
        put :update, params: {id: lead_source.to_param, lead_source: new_attributes}, session: valid_session
        expect(response).to redirect_to(lead_source)
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'edit' template)" do
        lead_source = create(:lead_source)
        put :update, params: {id: lead_source.to_param, lead_source: invalid_attributes}, session: valid_session
        expect(response).to be_success
      end
    end
  end

  describe "DELETE #destroy" do
    it "destroys the requested lead_source" do
      lead_source = create(:lead_source)
      expect {
        delete :destroy, params: {id: lead_source.to_param}, session: valid_session
      }.to change(LeadSource, :count).by(-1)
    end

    it "redirects to the lead_sources list" do
      lead_source = create(:lead_source)
      delete :destroy, params: {id: lead_source.to_param}, session: valid_session
      expect(response).to redirect_to(lead_sources_url)
    end
  end

  describe "POST #reset_token" do
    [:html, :json].each do |format|
      it "should reset the api token via a #{format} request" do
        lead_source = create(:lead_source)
        expect{
          post :reset_token, params: {id: lead_source.to_param}, format: format
          lead_source.reload
        }.to change(lead_source, :api_token)
      end
    end

  end

end
