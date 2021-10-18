require 'rails_helper'

RSpec.describe ProspectStats do

  describe "returning statistics" do
    include_context "users"
    include_context "messaging"

    let(:cobalt_source) { create(:cobalt_source) }
    let(:voyager_source) { create(:yardi_voyager_source) }
    let(:source) { create(:lead_source, slug: LeadSource::DEFAULT_SLUG) }
    let(:source2) { create(:lead_source, slug: 'source2') }
    let(:property) { create(:property) }
    let(:property2) { create(:property) }
    let(:property3) { create(:property) }
    let(:listing) { create(:property_listing, source_id: source.id, property_id: property.id) }
    let(:listing2) { create(:property_listing, source_id: source.id, property_id: property2.id) }
    let(:listing3) { create(:property_listing, source_id: source2.id, property_id: property3.id) }

    let(:lead1) { create(:lead, property: property, source: source, state: 'open') }
    let(:lead2) { create(:lead, property: property2, source: source, state: 'open') }
    let(:lead3) { create(:lead, property: property, source: source2) }
    let(:lead4) { create(:lead, property: property2, source: source2) }

    before do
      lead1; lead2; lead3; lead4
      lead1.trigger_event(event_name: 'claim', user: agent)
      lead2.trigger_event(event_name: 'claim', user: agent)
      listing; listing2; listing3
      cobalt_source; voyager_source
    end

    it "refreshes the cache" do
      stats = ProspectStats.new
      stats.refresh_cache
      stats.caching = false
      stats.property_stats
    end

  end

end
