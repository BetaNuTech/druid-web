require 'rails_helper'

RSpec.describe LeadsController, type: :controller do
  include_context "users"
  render_views

  let(:source) {
    create(:lead_source, slug: LeadSource::DEFAULT_SLUG)
  }

  # This should return the minimal set of attributes required to create a valid
  # Lead. As you add validations to Lead, be sure to
  # adjust the attributes here as well.
  let(:valid_attributes) {
    attributes_for(:lead)
  }

  let(:invalid_attributes) {
    attrs = attributes_for(:lead)
    attrs[:first_name] = nil
    attrs
  }

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # LeadsController. Be sure to keep this updated too.
  let(:valid_session) { {} }

  before do
    source
  end


  describe "GET #index" do
    include_examples "authenticated action", {params: {}, name: 'index'}

    it "returns a success response" do
      sign_in unroled_user
      lead = Lead.create! valid_attributes
      get :index, params: {}
      expect(response).to be_success
    end
  end

  describe "GET #show" do
    let(:lead) { Lead.create! valid_attributes }

    include_examples "authenticated action", {params: {id: 0 }, name: 'show'}

    it "returns a success response" do
      sign_in unroled_user
      get :show, params: {id: lead.to_param}
      expect(response).to be_success
    end

    it "can return JSON data" do
      sign_in unroled_user
      assert(lead.preference.present?)
      get :show, params: {id: lead.to_param}, format: :json
      expect(response).to be_success
    end
  end

  describe "GET #new" do
    include_examples "authenticated action", {params: {id: 0 }, name: 'new'}

    it "returns a success response" do
      sign_in unroled_user
      get :new, params: {}, session: valid_session
      expect(response).to be_success
    end
  end

  describe "GET #edit" do
    include_examples "authenticated action", {params: {id: 0 }, name: 'edit'}
    it "returns a success response" do
      sign_in unroled_user
      lead = Lead.create! valid_attributes
      get :edit, params: {id: lead.to_param}, session: valid_session
      expect(response).to be_success
    end
  end

  describe "POST #create" do
    include_examples "authenticated action", {params: {id: 0 }, name: 'create'}

    before do
      source
    end

    context "with valid params" do
      it "creates a new Lead" do
      sign_in unroled_user
        expect {
          post :create, params: {lead: valid_attributes}, session: valid_session
        }.to change(Lead, :count).by(1)
      end

      it "redirects to the created lead" do
      sign_in unroled_user
        post :create, params: {lead: valid_attributes}, session: valid_session
        expect(response).to redirect_to(Lead.last)
      end

      context "specifying a source id" do
        it "creates a lead with the source" do
      sign_in unroled_user
        post :create, params: {lead: valid_attributes.merge(lead_source_id: source.id) }, session: valid_session
        expect(response).to redirect_to(Lead.last)
        expect(Lead.last.source).to eq(source)
        end
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'new' template)" do
      sign_in unroled_user
        post :create, params: {lead: invalid_attributes}, session: valid_session
        expect(response).to be_success
      end
    end
  end

  describe "PUT #update" do
    include_examples "authenticated action", {params: {id: 0 }, name: 'update'}

    context "with valid params" do
      let(:new_attributes) {
        attributes_for(:lead).merge(notes: 'Foobar')
      }

      it "updates the requested lead" do
      sign_in unroled_user
        lead = Lead.create! valid_attributes
        put :update, params: {id: lead.to_param, lead: new_attributes}, session: valid_session
        lead.reload
        expect(lead.notes).to eq(new_attributes[:notes])
      end

      it "redirects to the lead" do
      sign_in unroled_user
        lead = Lead.create! valid_attributes
        put :update, params: {id: lead.to_param, lead: valid_attributes}, session: valid_session
        expect(response).to redirect_to(lead)
      end
    end

    context "with invalid params" do
      it "returns a success response (i.e. to display the 'edit' template)" do
      sign_in unroled_user
        lead = Lead.create! valid_attributes
        put :update, params: {id: lead.to_param, lead: invalid_attributes}, session: valid_session
        expect(response).to be_success
      end
    end
  end

  describe "DELETE #destroy" do
    it "redirects to login if unauthenticated" do
      lead = Lead.create! valid_attributes
      delete :destroy, params: {id: lead.to_param}, session: valid_session
      expect(response).to redirect_to(new_user_session_path)
    end

    it "destroys the requested lead" do
      sign_in unroled_user
      lead = Lead.create! valid_attributes
      expect {
        delete :destroy, params: {id: lead.to_param}, session: valid_session
      }.to change(Lead, :count).by(-1)
    end

    it "redirects to the leads list" do
      sign_in unroled_user
      lead = Lead.create! valid_attributes
      delete :destroy, params: {id: lead.to_param}, session: valid_session
      expect(response).to redirect_to(leads_url)
    end
  end

end
