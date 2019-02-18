require 'rails_helper'

RSpec.describe Leads::Adapters::YardiVoyager do
  include_context "users"

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
    create(:lead, property: property, state: 'prospect', remoteid: 'p123456', email: 'me@here.com', classification: 'lead')
  }

  describe "initialization" do
    before do
      manager
    end

    it "should initialize and set instance variables" do
      adapter
      expect(adapter.property).to eq(property)
      expect(adapter.lead_source).to eq(lead_source)
    end
  end

  describe "Guestcard/Lead creation" do
    let(:yardi_api_data) { File.read("#{Rails.root}/spec/support/test_data/yardi_voyager_guestcards.json") }
    let(:guestcards) {Yardi::Voyager::Data::GuestCard.from_GetYardiGuestActivity(yardi_api_data)}

    it "creates a new lead record from a guestcard (private method)" do
      guestcard = guestcards.first
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

    it "handles the creation of cancelled Guestcards/Disqualified Leads" do
      guestcard = guestcards.select{|gc| gc.record_type = 'canceled'}.first
      updated_lead = adapter.send(:lead_from_guestcard, guestcard)
      assert updated_lead.new_record?
      assert updated_lead.valid?
      assert updated_lead.save
      expect( updated_lead.state ).to eq('disqualified')
      expect( updated_lead.priority ).to eq('zero')
    end
  end

  describe "lead data import" do
    before do
      manager
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

  describe "data parsing" do
    describe "GuestCard" do

      let(:yardi_api_data) { JSON.parse(File.read("#{Rails.root}/spec/support/test_data/yardi_voyager_guestcards.json")) }
      let(:prospect_data) {
        yardi_api_data.dig("Envelope", "Body", "GetYardiGuestActivity_LoginResponse", "GetYardiGuestActivity_LoginResult", "LeadManagement", "Prospects", "Prospect")
      }

      let(:prospect_record) { prospect_data.first }

      it "should return a guestcard from a prospect data hash" do
        guestcard = Yardi::Voyager::Data::GuestCard.from_guestcard_node(prospect_record, false).first
        expect(guestcard).to be_a(Yardi::Voyager::Data::GuestCard)
      end
    end
  end
end
