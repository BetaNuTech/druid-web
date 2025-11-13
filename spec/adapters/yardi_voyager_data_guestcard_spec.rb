require 'rails_helper'

RSpec.describe Yardi::Voyager::Data::GuestCard do
  let(:yardi_api_data) { File.read("#{Rails.root}/spec/support/test_data/yardi_voyager_guestcards.json") }
  let(:adapter) { Yardi::Voyager::Data::GuestCard }

  it "should return GuestCards from a Voyager GetYardiGuestActivity API call and optionally filter unwanted Prospects" do
    filtered_guestcards = adapter.from_GetYardiGuestActivity(yardi_api_data, true)
    all_guestcards = adapter.from_GetYardiGuestActivity(yardi_api_data, false)

    all_types = []
    filtered_types = Yardi::Voyager::Data::GuestCard::ACCEPTED_CUSTOMER_TYPES
    expect(filtered_guestcards.size).to eq(264)
    expect(all_guestcards.size).to eq(429)

    # Filtered GuestCards record types
    expect(filtered_guestcards.map(&:record_type).sort.index("roommate")).to eq(nil)

    # Includes canceled [sic] GuestCards
    expect(all_guestcards.map(&:record_type).sort.index("canceled")).to_not eq(nil)
  end

  it "should fetch guestcard attributes" do
    all_guestcards = adapter.from_GetYardiGuestActivity(yardi_api_data, false)
    guestcard = all_guestcards.first

    refute(guestcard.first_comm.nil?)
    refute(guestcard.first_name.nil?)
    refute(guestcard.last_name.nil?)
    refute(guestcard.property_id.nil?)
  end

  describe ".lead_guestcard_type" do
    it "maps early pipeline states to prospect" do
      ['open', 'prospect', 'showing', 'application', 'approved'].each do |state|
        lead = double('Lead', state: state)
        expect(adapter.lead_guestcard_type(lead)).to eq('prospect')
      end
    end

    it "maps denied state to canceled" do
      lead = double('Lead', state: 'denied')
      expect(adapter.lead_guestcard_type(lead)).to eq('canceled')
    end

    it "maps resident states to Yardi resident types" do
      lead = double('Lead', state: 'resident')
      expect(adapter.lead_guestcard_type(lead)).to eq('current_resident')

      lead = double('Lead', state: 'exresident')
      expect(adapter.lead_guestcard_type(lead)).to eq('former_resident')
    end

    it "maps future state to prospect (nurtured leads)" do
      lead = double('Lead', state: 'future')
      expect(adapter.lead_guestcard_type(lead)).to eq('prospect')
    end

    it "maps invalidated state to canceled (spam/fake leads)" do
      lead = double('Lead', state: 'invalidated')
      expect(adapter.lead_guestcard_type(lead)).to eq('canceled')
    end

    it "defaults unknown states to prospect" do
      lead = double('Lead', state: 'unknown_state')
      expect(adapter.lead_guestcard_type(lead)).to eq('prospect')
    end
  end

end
