require 'rails_helper'

RSpec.describe Leads::Adapters::YardiVoyager do
  let(:property_code) { 'marble' }
  let(:property) { create(:property) }
  let(:lead_source) { create(:yardi_voyager_source)}
  let(:listing) { create(:property_listing, code: property_code, property: property, source: lead_source)}
  let(:initial_params) {
    listing
    { property_code: property_code }
  }
  let(:adapter) { Leads::Adapters::YardiVoyager.new(initial_params) }
  let(:lead) {
    create(:lead, property: property, state: 'prospect', remoteid: 'p123456')
  }

  describe "initialization" do
    it "should initialize and set instance variables" do
      adapter
      expect(adapter.property).to eq(property)
      expect(adapter.lead_source).to eq(lead_source)
    end

    it "creates a new lead record from a guestcard (private method)" do
      guestcard = Yardi::Voyager::Data::GuestCard.from_lead(lead, property_code)
      lead.remoteid = nil
      lead.save!
      guestcard.record_type = 'application'
      updated_lead = adapter.send(:lead_from_guestcard, guestcard)
      assert updated_lead.new_record?
      assert updated_lead.valid?
    end

    it "initializes an existing lead from a guestcard (private method)" do
      guestcard = Yardi::Voyager::Data::GuestCard.from_lead(lead, property_code)
      guestcard.record_type = 'applicant'
      updated_lead = adapter.send(:lead_from_guestcard, guestcard)
      expect(updated_lead.id).to eq(lead.id)
    end

    it "progresses existing lead state from a guestcard (private method)" do
      guestcard = Yardi::Voyager::Data::GuestCard.from_lead(lead, property_code)
      guestcard.record_type = 'applicant'
      updated_lead = adapter.send(:lead_from_guestcard, guestcard)
      expect(updated_lead.state).to eq('application')
      lead.reload
      expect(lead.state).to eq('application')
    end
  end
end
