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

  describe "Lea AI Admin agent assignment" do
    let(:lea_property) { create(:property, :with_lea_ai) }
    let(:regular_property) { create(:property) }
    let(:system_user) { User.system }
    let(:regular_user) { create(:user) }

    before do
      # Stub voyager_property_code method for both properties
      allow(lea_property).to receive(:voyager_property_code).and_return('TEST123')
      allow(regular_property).to receive(:voyager_property_code).and_return('REG456')
    end

    it "uses Admin agent for system user leads on Lea AI properties" do
      lead = create(:lead, user: system_user, property: lea_property, state: 'open', remoteid: nil)

      xml = Yardi::Voyager::Data::GuestCard.to_xml_2(lead: lead, include_events: true)

      # Agent is in Events > Event > Agent > AgentName
      expect(xml).to include('<FirstName>Admin</FirstName>')
      expect(xml).to match(/<LastName\s*\/?>/)
    end

    it "uses regular agent for non-system user leads on Lea AI properties" do
      lead = create(:lead, user: regular_user, property: lea_property, state: 'open', remoteid: nil)

      xml = Yardi::Voyager::Data::GuestCard.to_xml_2(lead: lead, include_events: true)

      expect(xml).to include("<AgentName><FirstName>#{regular_user.first_name}</FirstName><LastName>#{regular_user.last_name}</LastName></AgentName>")
    end

    it "uses None agent for unassigned leads (nil user) on Lea AI properties" do
      lead = create(:lead, user: nil, property: lea_property, state: 'open', remoteid: nil)

      xml = Yardi::Voyager::Data::GuestCard.to_xml_2(lead: lead, include_events: true)

      # Unassigned leads should NOT get "Admin" agent
      expect(xml).not_to include('<FirstName>Admin</FirstName>')
      # Should get either creditable agent or "None None"
      expect(xml).to include('<AgentName>')
    end

    it "uses None agent for system user leads on non-Lea-AI properties" do
      lead = create(:lead, user: system_user, property: regular_property, state: 'open', remoteid: nil)

      xml = Yardi::Voyager::Data::GuestCard.to_xml_2(lead: lead, include_events: true)

      # System user on non-Lea property should NOT get "Admin" (only Lea AI properties get Admin)
      expect(xml).not_to include('<FirstName>Admin</FirstName>')
      # Should get creditable agent or system user's actual name (Bluesky)
      expect(xml).to include('<AgentName>')
    end

    it "uses creditable agent when available instead of assigned user" do
      credited_user = create(:user)
      lead = create(:lead, user: regular_user, property: lea_property, state: 'open', remoteid: nil)

      # Stub creditable_agent to return a different user
      allow(lead).to receive(:creditable_agent).and_return(credited_user)

      xml = Yardi::Voyager::Data::GuestCard.to_xml_2(lead: lead, include_events: true)

      expect(xml).to include("<AgentName><FirstName>#{credited_user.first_name}</FirstName><LastName>#{credited_user.last_name}</LastName></AgentName>")
    end

    it "handles system user with Lea handoff lead (has conversation URL)" do
      # Create unique email to avoid duplicate validation error
      unique_email = "lea_handoff_#{SecureRandom.hex(4)}@example.com"
      lead = create(:lead, user: system_user, property: lea_property, state: 'open', remoteid: nil,
                    lea_conversation_url: 'https://lea.example.com/conversation/abc123',
                    email: unique_email)

      xml = Yardi::Voyager::Data::GuestCard.to_xml_2(lead: lead, include_events: true)

      # Should use Admin since it's system user on Lea AI property
      expect(xml).to include('<FirstName>Admin</FirstName>')
      expect(xml).to match(/<LastName\s*\/?>/)
    end
  end

end
