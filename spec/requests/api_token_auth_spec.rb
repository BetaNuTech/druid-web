require 'rails_helper'

# The lead API authenticates with lead-source tokens, not Devise sessions.
# Adding Google sign-in (Devise :omniauthable, the OmniAuth middleware) must not
# change that: these go through the full middleware stack with Google sign-in
# switched on.
RSpec.describe 'Lead API token authentication', type: :request do
  include_context 'messaging'

  let(:source) { create(:lead_source, slug: LeadSource::DEFAULT_SLUG) }

  before do
    allow(GoogleSignIn).to receive(:enabled?).and_return(true)
    source
  end

  it 'creates a lead with a valid token and no session' do
    expect {
      post '/api/v1/leads.json', params: attributes_for(:lead).merge(token: source.api_token)
    }.to change(Lead, :count).by(1)

    expect(response).to have_http_status(:created)
    expect(JSON.parse(response.body)['id']).to eq(Lead.last.id)
  end

  it 'refuses an invalid token' do
    expect {
      post '/api/v1/leads.json', params: attributes_for(:lead).merge(token: 'not valid')
    }.not_to change(Lead, :count)

    expect(response).to have_http_status(:forbidden)
    expect(JSON.parse(response.body).dig('errors', 'base', 0)).to eq('Invalid Access Token')
  end
end
