require 'rails_helper'

RSpec.describe "home page", type: :request do
  it "renders the home page" do
    get "/"
    expect(response).to have_http_status(:ok)
  end
end
