RSpec.shared_context 'lead_creator' do
  include_context "users"

  let(:default_lead_source) { create(:lead_source, slug: LeadSource::DEFAULT_SLUG) }
  let(:lead_creator_property) { agent.property }
  let(:lead_creator_property_listing) { create(:property_listing, source_id: default_lead_source.id, property_id: lead_creator_property.id) }

  let(:valid_lead_creator_attributes) {
    {
      data: FactoryBot.attributes_for(:lead),
      token: default_lead_source.api_token,
      agent: nil
    }
  }

end
