require 'rails_helper'

RSpec.describe Api::V1::SwaggerController, type: :controller do
  render_views

  let(:bluesky_source) { create(:bluesky_source) }
  let(:zillow_source) { create(:zillow_source) }

  describe "GET #index" do
    it "should render swagger JSON for bluesky" do
      get :index, params: { token: druid_source.api_token }, format: :json
      expect(response).to be_successful
    end

    it "should render swagger JSON for zillow" do
      get :index, params: { token: zillow_source.api_token }, format: :json
      expect(response).to be_successful
    end

    it "should raise a 404 error if the source is not found" do
      expect{
        get :index, params: { token: 'invalid_token' }, format: :json
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

  end

  describe "GET #apidocs" do
    it "should render the Swagger index HTML from public/" do
      get :apidocs, params: { token: druid_source.api_token }
      expect(response).to be_successful
    end
  end
end
