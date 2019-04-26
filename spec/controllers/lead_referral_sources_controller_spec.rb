require 'rails_helper'

RSpec.describe LeadReferralSourcesController, type: :controller do
  include_context 'users'
  render_views

  describe "GET #index" do
    describe "as an admin" do
      it "returns a success response" do
        sign_in administrator
        get :index, params: {}
        expect(response).to be_successful
      end
    end
    describe "as an agent" do
      it "redirects" do
        sign_in agent
        get :index, params: {}
        expect(response).to be_redirect
      end
    end
  end

  describe "GET #new" do
    describe "as an admin" do
      it "returns a success response" do
        sign_in administrator
        get :new, params: {}
        expect(response).to be_successful
      end
    end
    describe "as an agent" do
      it "redirects" do
        sign_in agent
        get :new, params: {}
        expect(response).to be_redirect
      end
    end
  end

  describe "POST #create" do
    let(:valid_attributes) { attributes_for(:lead_referral_source) }
    describe "as an admin" do
      it "creates a new record" do
        sign_in administrator
        old_count = LeadReferralSource.count
        post :create, params: {lead_referral_source: valid_attributes}
        expect(response).to redirect_to(lead_referral_source_path(assigns[:lead_referral_source]))
        expect(LeadReferralSource.count).to eq(old_count + 1)
      end
    end
    describe "as an agent" do
      it "redirects" do
        sign_in agent
        get :new, params: {}
        expect(response).to be_redirect
      end
    end
  end

  describe "GET #show" do
    let(:lead_referral_source) { create(:lead_referral_source) }
    describe "as an admin" do
      it "returns a success response" do
        sign_in administrator
        get :show, params: {id: lead_referral_source.id}
        expect(response).to be_successful
      end
    end
    describe "as an agent" do
      it "redirects" do
        sign_in agent
        get :show, params: {id: lead_referral_source.id}
        expect(response).to be_redirect
      end
    end
  end

  describe "GET #edit" do
    let(:lead_referral_source) { create(:lead_referral_source) }
    describe "as an admin" do
      it "returns a success response" do
        sign_in administrator
        get :edit, params: {id: lead_referral_source.id}
        expect(response).to be_successful
      end
    end
    describe "as an agent" do
      it "redirects" do
        sign_in agent
        get :edit, params: {id: lead_referral_source.id}
        expect(response).to be_redirect
      end
    end
  end


  describe "UPDATE #update" do
    let(:lead_referral_source) { create(:lead_referral_source) }
    let(:valid_attributes) { {name: 'Foobar'}}
    let(:invalid_attributes) { {name: nil}}
    describe "as an admin" do
      it "with valid attributes updates the record" do
        sign_in administrator
        put :update, params: {id: lead_referral_source.id, lead_referral_source: valid_attributes}
        expect(response).to redirect_to(lead_referral_source_path(assigns[:lead_referral_source]))
        lead_referral_source.reload
        expect(lead_referral_source.name).to eq(valid_attributes[:name])
      end
      it "with invalid attributes does not update the record" do
        sign_in administrator
        put :update, params: {id: lead_referral_source.id, lead_referral_source: invalid_attributes}
        expect(response).to render_template(:edit)
        lead_referral_source.reload
        expect(lead_referral_source.name).to_not eq(valid_attributes[:name])
      end
    end
    describe "as an agent" do
      it "redirects" do
        sign_in agent
        put :update, params: {id: lead_referral_source.id, lead_referral_source: valid_attributes}
        expect(response).to be_redirect
        lead_referral_source.reload
        expect(lead_referral_source.name).to_not eq(valid_attributes[:name])
      end
    end
  end

  describe "DELETE #destroy" do
    let(:lead_referral_source) { create(:lead_referral_source) }
    describe "as an administrator" do
      it "deletes the record" do
        sign_in administrator
        lead_referral_source
        old_count = LeadReferralSource.count
        delete :destroy, params: {id: lead_referral_source.id}
        expect(response).to redirect_to(lead_referral_sources_path)
        expect(LeadReferralSource.count).to eq(old_count - 1)
      end
    end
    describe "as an agent" do
      it "does not delete the record" do
        sign_in agent
        lead_referral_source
        old_count = LeadReferralSource.count
        delete :destroy, params: {id: lead_referral_source.id}
        expect(response).to be_redirect
        expect(LeadReferralSource.count).to eq(old_count)
      end
    end
  end
end
