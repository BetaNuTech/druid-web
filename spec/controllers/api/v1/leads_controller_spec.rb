require 'rails_helper'

RSpec.describe Api::V1::LeadsController, type: :controller do
  render_views

  let(:source) {
    create(:lead_source, slug: LeadSource::DEFAULT_SLUG)
  }

  let(:valid_attributes_for_druid) {
    base_attrs = attributes_for(:lead)
    base_attrs[:source] = source.slug
    base_attrs[:token] = source.api_token
    base_attrs
  }

  let(:valid_attributes_for_druid_invalid_token) {
    base_attrs = attributes_for(:lead)
    base_attrs[:source] = source.slug
    base_attrs[:token] = 'not valid'
    base_attrs
  }

  let(:invalid_attributes_for_druid) {
    base_attrs = attributes_for(:lead)
    base_attrs[:first_name] = nil
    base_attrs[:source] = source.slug
    base_attrs[:token] = source.api_token
    base_attrs
  }

  describe "POST #create" do
    describe "using the Druid Adapter" do
      before do
        source
      end

      context "with valid params" do
        it "creates a new Lead" do
          expect {
            post :create, params: valid_attributes_for_druid, format: :json
          }.to change(Lead, :count).by(1)
          new_lead = Lead.last
          response_json = JSON.parse(response.body)
          expect(response_json["id"]).to eq(new_lead.id)
          expect(response_json["preference"]["min_area"]).to eq(new_lead.preference.min_area)
        end

        it "fails to create a new Lead with an invalid token" do
          expect {
            post :create, params: valid_attributes_for_druid_invalid_token, format: :json
          }.to change(Lead, :count).by(0)
          response_json = JSON.parse(response.body)
          expect(response_json["errors"]).to_not be_nil
          expect(response_json["errors"]["base"][0]).to match('Invalid Access Token')
        end

      end

      context "with invalid params" do
        it "does not create a new lead" do
          expect {
            post :create, params: invalid_attributes_for_druid, format: :json
          }.to change(Lead, :count).by(0)
          response_json = JSON.parse(response.body)
          expect(response_json["errors"]).to_not be_nil
          expect(response_json["errors"]["first_name"][0]).to eq("can't be blank")
        end
      end
    end
  end
end
