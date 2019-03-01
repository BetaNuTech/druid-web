require 'rails_helper'

RSpec.describe Api::V1::LeadsController, type: :controller do
  render_views

  let(:source) {
    create(:lead_source, slug: LeadSource::DEFAULT_SLUG)
  }

  let(:valid_attributes_for_bluesky) {
    base_attrs = attributes_for(:lead)
    base_attrs[:token] = source.api_token
    base_attrs
  }

  let(:valid_attributes_for_bluesky_invalid_token) {
    base_attrs = attributes_for(:lead)
    base_attrs[:token] = 'not valid'
    base_attrs
  }

  let(:invalid_attributes_for_bluesky) {
    base_attrs = attributes_for(:lead)
    base_attrs[:first_name] = nil
    base_attrs[:token] = source.api_token
    base_attrs
  }

  describe "POST #create" do
    describe "using the BlueSky Adapter" do
      before do
        source
      end

      context "with valid params" do
        it "creates a new Lead" do
          expect {
            post :create, params: valid_attributes_for_bluesky, format: :json
          }.to change(Lead, :count).by(1)
          new_lead = Lead.last
          response_json = JSON.parse(response.body)
          expect(response_json["id"]).to eq(new_lead.id)
          expect(response_json["preference"]["min_area"]).to eq(new_lead.preference.min_area)
        end

        it "fails to create a new Lead with an invalid token" do
          expect {
            post :create, params: valid_attributes_for_bluesky_invalid_token, format: :json
          }.to change(Lead, :count).by(0)
          response_json = JSON.parse(response.body)
          expect(response).to have_http_status(:forbidden)
          expect(response_json["errors"]).to_not be_nil
          expect(response_json["errors"]["base"][0]).to match('Invalid Access Token')
        end

      end

      context "with invalid params" do
        it "does not create a new lead" do
          expect {
            post :create, params: invalid_attributes_for_bluesky, format: :json
          }.to change(Lead, :count).by(0)
          response_json = JSON.parse(response.body)
          expect(response_json["errors"]).to_not be_nil
          expect(response_json["errors"]["first_name"][0]).to eq("can't be blank")
        end
      end
    describe "using the Costar Adapter" do
      let(:source) { create(:lead_source, slug: 'Costar', name: 'Costar')}

      before do
        source
      end

      context "with valid params" do
        it "creates a new Lead" do
          expect {
            post :create, params: valid_attributes_for_bluesky, format: :json
          }.to change(Lead, :count).by(1)
          new_lead = Lead.last
          response_json = JSON.parse(response.body)
          expect(response_json["id"]).to eq(new_lead.id)
          expect(response_json["preference"]["min_area"]).to eq(new_lead.preference.min_area)
          expect(new_lead.source.slug).to eq('Costar')
        end

        it "fails to create a new Lead with an invalid token" do
          expect {
            post :create, params: valid_attributes_for_bluesky_invalid_token, format: :json
          }.to change(Lead, :count).by(0)
          response_json = JSON.parse(response.body)
          expect(response).to have_http_status(:forbidden)
          expect(response_json["errors"]).to_not be_nil
          expect(response_json["errors"]["base"][0]).to match('Invalid Access Token')
        end

      end

      context "with invalid params" do
        it "does not create a new lead" do
          expect {
            post :create, params: invalid_attributes_for_bluesky, format: :json
          }.to change(Lead, :count).by(0)
          response_json = JSON.parse(response.body)
          expect(response_json["errors"]).to_not be_nil
          expect(response_json["errors"]["first_name"][0]).to eq("can't be blank")
        end
      end
    end
    end
  end

  describe "#GET index" do
    let(:source) { create(:lead_source, slug: LeadSource::DEFAULT_SLUG) }
    let(:source2) { create(:lead_source, slug: 'source2') }
    let(:property) { create(:property) }
    let(:property2) { create(:property) }
    let(:property3) { create(:property) }
    let(:listing) { create(:property_listing, source_id: source.id, property_id: property.id) }
    let(:listing2) { create(:property_listing, source_id: source.id, property_id: property2.id) }
    let(:listing3) { create(:property_listing, source_id: source2.id, property_id: property3.id) }

    let(:lead1) { create(:lead, property: property, source: source) }
    let(:lead2) { create(:lead, property: property2, source: source) }
    let(:lead3) { create(:lead, property: property, source: source2) }
    let(:lead4) { create(:lead, property: property2, source: source2) }

    before do
      lead1; lead2; lead3; lead4
      listing; listing2; listing3
    end

    it "should refuse invalid tokens" do
      get :index, params: {token: 'invalid'}
      expect(response).to have_http_status(:forbidden)
      get :index, params: {}
      expect(response).to have_http_status(:forbidden)
    end

    it "should return leads for the source associated with the provided token" do
      get :index, params: {token: source.api_token}, format: :json
      expect(response).to be_successful
      response_json = JSON.parse(response.body)
      expect(response_json.size).to eq(2)
      expect(response_json[0]["id"]).to eq(lead2.id)
      expect(response_json[0]["property"]["id"]).to eq(property2.id)
      expect(response_json[1]["id"]).to eq(lead1.id)
      expect(response_json[1]["property"]["id"]).to eq(property.id)
    end

    it "should limit the number of leads returned" do
      record_limit = 1
      get :index, params: {token: source.api_token, limit: record_limit}, format: :json
      expect(response).to be_successful
      response_json = JSON.parse(response.body)
      expect(response_json.size).to eq(record_limit)
    end
  end
end
