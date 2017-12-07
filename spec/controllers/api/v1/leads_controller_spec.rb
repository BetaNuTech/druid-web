require 'rails_helper'

RSpec.describe Api::V1::LeadsController, type: :controller do
  render_views

  let(:valid_attributes_for_druid) {
    base_attrs = attributes_for(:lead)
    base_attrs[:source] = 'Druid'
    base_attrs
  }

  let(:invalid_attributes_for_druid) {
    base_attrs = attributes_for(:lead)
    base_attrs[:first_name] = nil
    base_attrs[:source] = 'Druid'
    base_attrs
  }

  describe "POST #create" do
    describe "using the Druid Adapter" do
      before do
        create(:lead_source, slug: 'Druid')
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

      end

      context "with invalid params" do
        it "does not create a new lead" do
          expect {
            post :create, params: invalid_attributes_for_druid, format: :json
          }.to change(Lead, :count).by(0)
          response_json = JSON.parse(response.body)
          expect(response_json["first_name"][0]).to eq("can't be blank")
        end
      end
    end
  end
end
