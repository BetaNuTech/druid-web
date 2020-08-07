require 'rails_helper'

RSpec.describe MarketingSourcesController, type: :controller do
  include_context 'users'
  render_views

  let(:lead_source) { create(:bluesky_source) }
  let(:property) { agent.property }
  let(:new_name_attribute) { 'foobar0000' }
  let(:marketing_source) { create(:marketing_source, property_id: property.id, lead_source: lead_source) }
  let(:valid_attributes) { attributes_for(:marketing_source, name: new_name_attribute, property_id: property.id) }
  let(:invalid_attributes) { attributes_for(:marketing_source, name: new_name_attribute, start_date: nil) }

  before(:each) do
    lead_source
  end

  describe "GET #index" do
    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        get :index, params: {property_id: property.id}
        expect(response).to be_redirect
      end
    end

    describe "as an agent" do
      it "should fail" do
        sign_in agent
        get :index, params: {property_id: property.id}
        expect(response).to be_redirect
      end
    end

    describe "as a manager" do
      it "should succeed" do
        sign_in manager
        get :index, params: {property_id: property.id}
        expect(response).to be_successful
        expect(response).to render_template(:index)
      end
    end

    describe "as a corporate user" do
      it "should succeed" do
        sign_in corporate
        get :index, params: {property_id: property.id}
        expect(response).to be_successful
        expect(response).to render_template(:index)
      end
    end
  end # GET #index

  describe "GET #new" do
    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        get :new, params: {property_id: property.id}
        expect(response).to be_redirect
      end
    end

    describe "as an agent" do
      it "should fail" do
        sign_in agent
        get :new, params: {property_id: property.id}
        expect(response).to be_redirect
      end
    end

    describe "as a manager" do
      it "should fail" do
        sign_in manager
        get :new, params: {property_id: manager.property.id}
        expect(response).to be_redirect
      end
    end

    describe "as a corporate user" do
      it "should succeed" do
        sign_in corporate
        get :new, params: {property_id: property.id}
        expect(response).to be_successful
        expect(response).to render_template(:new)
      end
    end
  end # GET #new

  describe "POST #create" do
    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        post :create, params: {marketing_source: valid_attributes}
        expect(assigns[:marketing_source]).to be_nil
        expect(response).to be_redirect
      end
    end

    describe "as an agent" do
      it "should fail" do
        sign_in agent
        post :create, params: {marketing_source: valid_attributes}
        refute(assigns[:marketing_source].valid?)
        expect(response).to be_redirect
      end
    end

    describe "as a manager" do
      it "should fail" do
        sign_in manager
        post :create, params: {marketing_source: valid_attributes}
        expect(response).to be_redirect
      end
    end

    describe "as a corporate user" do
      it "should succeed" do
        sign_in corporate
        post :create, params: {marketing_source: valid_attributes}
        expect(assigns[:marketing_source]).to be_valid
        expect(response).to redirect_to(marketing_sources_path + "##{assigns[:marketing_source].id}")
      end

      describe "with invalid data" do
        it "should rerender the form" do
          sign_in corporate
          post :create, params: {marketing_source: {name: 'foo'}}
          expect(assigns[:marketing_source]).to_not be_valid
          expect(response).to render_template('new')
        end
      end
    end
  end # POST #create

  describe "GET #show" do
    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        get :show, params: {id: marketing_source.id}
        expect(response).to be_redirect
      end
    end

    describe "as an agent" do
      it "should fail" do
        sign_in agent
        expect {
          get :show, params: {id: marketing_source.id}
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe "as a manager" do
      it "should succeed" do
        sign_in manager
        get :show, params: {id: marketing_source.id}
        expect(response).to be_successful
        expect(response).to render_template(:show)
      end
    end

    describe "as a corporate user" do
      it "should succeed" do
        sign_in corporate
        get :show, params: {id: marketing_source.id}
        expect(response).to be_successful
        expect(response).to render_template(:show)
      end
    end
  end # GET #show

  describe "GET #edit" do
    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        get :edit, params: {id: marketing_source.id}
        expect(response).to be_redirect
      end
    end

    describe "as an agent" do
      it "should fail" do
        sign_in agent
        expect {
          get :edit, params: {id: marketing_source.id}
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe "as a manager" do
      it "should succeed" do
        sign_in manager
        get :edit, params: {id: marketing_source.id}
        expect(response).to be_redirect
      end
    end

    describe "as a corporate user" do
      it "should succeed" do
        sign_in corporate
        get :edit, params: {id: marketing_source.id}
        expect(response).to be_successful
        expect(response).to render_template(:edit)
      end
    end
  end # GET #edit

  describe "PUT #update" do
    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        put :update, params: {id: marketing_source.id, marketing_source: valid_attributes}
        expect(response).to be_redirect
      end
    end

    describe "as an agent" do
      it "should fail" do
        sign_in agent
        expect {
          put :update, params: {id: marketing_source.id, marketing_source: valid_attributes}
        }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    describe "with valid attributes" do
      describe "as a manager" do
        it "should fail" do
          sign_in manager
          put :update, params: {id: marketing_source.id, marketing_source: valid_attributes}
          marketing_source.reload
          expect(marketing_source.name).to_not eq(new_name_attribute)
        end
      end

      describe "as a corporate user" do
        it "should succeed" do
          sign_in corporate
          put :update, params: {id: marketing_source.id, marketing_source: valid_attributes}
          marketing_source.reload
          expect(marketing_source.name).to eq(new_name_attribute)
          expect(response).to redirect_to(marketing_sources_path + "##{assigns[:marketing_source].id}")
        end
      end
    end

    describe "with invalid attributes" do
      describe "as a manager" do
        it "should fail" do
          sign_in manager
          put :update, params: {id: marketing_source.id, marketing_source: invalid_attributes}
          marketing_source.reload
          expect(marketing_source.name).to_not eq(new_name_attribute)
          expect(response).to be_redirect
        end
      end

      describe "as a corporate user" do
        it "should fail validation" do
          sign_in corporate
          put :update, params: {id: marketing_source.id, marketing_source: invalid_attributes}
          marketing_source.reload
          expect(marketing_source.name).to_not eq(new_name_attribute)
          expect(response).to render_template(:edit)
        end
      end

    end
  end # PUT #update

  describe "DELETE #destroy" do
    before do
      marketing_source
    end

    describe "as an unauthenticated user" do
      it "should fail and redirect" do
        count = MarketingSource.count
        delete :destroy, params: { id: marketing_source.id }
        expect(response).to be_redirect
        expect(MarketingSource.count).to eq(count)
      end
    end

    describe "as an agent" do
      it "should fail" do
        sign_in agent
        count = MarketingSource.count
        expect {
          delete :destroy, params: { id: marketing_source.id }
        }.to raise_error(ActiveRecord::RecordNotFound)
        expect(MarketingSource.count).to eq(count)
      end
    end

    describe "as a manager" do
      it "should fail" do
        count = MarketingSource.count
        sign_in manager
        delete :destroy, params: { id: marketing_source.id }
        expect(MarketingSource.count).to eq(count)
      end
    end

    describe "as a corporate user" do
      it "should succeed" do
        count = MarketingSource.count
        sign_in corporate
        delete :destroy, params: { id: marketing_source.id }
        expect(MarketingSource.count).to eq(count - 1)
        expect(response).to redirect_to(marketing_sources_path)
      end
    end
  end

  describe "GET #form_suggest_tracking_details" do
    it "should succeed" do
      sign_in corporate
      get :form_suggest_tracking_details, params: { property_id: marketing_source.property_id, lead_source_id: marketing_source.lead_source }, format: :json
      expect(response).to be_successful
    end
  end

  describe "GET #report" do
    describe "as html" do
      it "should be successful" do
        sign_in corporate
        get :report, format: :html
        expect(response).to be_successful
      end
    end
    describe "as csv" do
      it "should be successful" do
        sign_in corporate
        get :report, format: :csv
        expect(response).to be_successful
      end

    end
  end

end
