require 'rails_helper'

RSpec.describe Leads::TourGuestcardPusher do
  include_context 'users'

  let(:property) { create(:property) }
  let(:voyager_source) { create(:lead_source, slug: 'YardiVoyager', name: 'YardiVoyager2') }
  let(:voyager_code) { 'testcode' }
  let!(:property_listing) { create(:property_listing, property: property, source: voyager_source, code: voyager_code, active: true) }

  let(:api) { instance_double(Yardi::Voyager::Api::GuestCards) }
  let(:adapter) { instance_double(Leads::Adapters::YardiVoyager) }
  let(:pusher) { described_class.new }

  let(:yardi_agents) { ['Portal', 'Admin', 'Lea-Lite', 'Lea-Pro', 'Agent One', 'Agent Two'] }

  def create_tour_lead(attrs = {})
    lead = create(:lead, { property: property, state: 'open', user_id: nil, remoteid: nil }.merge(attrs))
    Note.create!(notable: lead, classification: 'system',
                 content: 'Tour Booking detected - Lead requires agent follow-up for scheduled tour')
    lead
  end

  before do
    allow(Yardi::Voyager::Api::GuestCards).to receive(:new).and_return(api)
    allow(Leads::Adapters::YardiVoyager).to receive(:new).and_return(adapter)
    allow(pusher).to receive(:sleep)
    allow(api).to receive(:getAgents).with(voyager_code).and_return(yardi_agents)
  end

  describe '#push_property' do
    it 'links leads that already have a Yardi guestcard' do
      lead = create_tour_lead
      guestcard = double('GuestCard', prospect_id: 'p0001111')
      allow(adapter).to receive(:findLeadGuestCard).with(lead).and_return(guestcard)

      result = pusher.push_property(property)

      expect(result[:linked]).to eq(1)
      expect(result[:created]).to eq(0)
      expect(lead.reload.remoteid).to eq('p0001111')
    end

    it 'creates guestcards with forced referral, tour comment, and a rotating Yardi agent' do
      lead = create_tour_lead(referral: 'Google Business Profile')
      lead.preference.update_columns(notes: "Tour scheduled for Jul 30 at 2pm\n\nLead has consented to receiving text messages.\n\nProcessed by AI")
      allow(adapter).to receive(:findLeadGuestCard).and_return(nil)

      sent_agent = nil
      sent_comment = nil
      allow(api).to receive(:sendGuestCard) do |args|
        sent_agent = args[:agent]
        sent_comment = args[:first_contact_comment]
        args[:lead].remoteid = 'p0002222'
        args[:lead]
      end

      result = pusher.push_property(property)

      expect(result[:created]).to eq(1)
      expect(lead.reload.remoteid).to eq('p0002222')
      expect(lead.referral).to eq('Property Website')
      expect(['Agent One', 'Agent Two']).to include("#{sent_agent.profile.first_name} #{sent_agent.profile.last_name}")
      expect(sent_comment).to include('Self-booked tour lead.')
      expect(sent_comment).to include('Tour scheduled for Jul 30 at 2pm')
      expect(sent_comment).to_not include('consented to receiving text')
      expect(sent_comment).to_not include('Processed by AI')
      expect(Note.where(notable: lead).where("content LIKE 'Referral changed%'")).to exist
    end

    it 'rotates agents round-robin across created guestcards' do
      3.times { create_tour_lead }
      allow(adapter).to receive(:findLeadGuestCard).and_return(nil)
      used_agents = []
      allow(api).to receive(:sendGuestCard) do |args|
        used_agents << "#{args[:agent].profile.first_name} #{args[:agent].profile.last_name}"
        args[:lead].remoteid = "p#{rand(100000)}"
        args[:lead]
      end

      pusher.push_property(property)

      # Two eligible agents, three creates: each agent used at least once
      expect(used_agents.uniq.sort).to eq(['Agent One', 'Agent Two'])
    end

    it 'never uses Yardi system agents' do
      create_tour_lead
      allow(adapter).to receive(:findLeadGuestCard).and_return(nil)
      allow(api).to receive(:sendGuestCard) do |args|
        expect(described_class::SYSTEM_AGENT_NAMES).to_not include("#{args[:agent].profile.first_name} #{args[:agent].profile.last_name}".strip)
        args[:lead].remoteid = 'p0003333'
        args[:lead]
      end

      pusher.push_property(property)
    end

    it 'skips a lead when the Yardi dedup search fails' do
      lead = create_tour_lead
      allow(adapter).to receive(:findLeadGuestCard).and_raise('Voyager unavailable')

      result = pusher.push_property(property)

      expect(result[:skipped_leads]).to eq(1)
      expect(result[:created]).to eq(0)
      expect(lead.reload.remoteid).to be_blank
    end

    it 'skips the property with an error when no eligible Yardi agents exist' do
      create_tour_lead
      allow(api).to receive(:getAgents).with(voyager_code).and_return(['Portal', 'Admin'])

      result = pusher.push_property(property)

      expect(result[:error]).to be_present
      expect(result[:pending]).to eq(1)
    end

    it 'retries agent fetch and reports an error after final failure' do
      create_tour_lead
      allow(api).to receive(:getAgents).and_raise('Voyager unavailable')

      result = pusher.push_property(property)

      expect(api).to have_received(:getAgents).exactly(described_class::MAX_ATTEMPTS).times
      expect(result[:error]).to be_present
    end

    it 'does nothing when there are no candidate leads' do
      result = pusher.push_property(property)

      expect(result).to include(linked: 0, created: 0)
      expect(api).to_not have_received(:getAgents)
    end

    it 'ignores tour leads that already have a remoteid or are not open' do
      create_tour_lead(remoteid: 'p0009999')
      synced = create_tour_lead
      synced.update_columns(state: 'prospect')

      result = pusher.push_property(property)

      expect(result).to include(linked: 0, created: 0)
    end
  end

  describe 'dry run' do
    it 'previews actions without writing anything' do
      linked_lead = create_tour_lead
      created_lead = create_tour_lead(referral: 'Zillow')
      guestcard = double('GuestCard', prospect_id: 'p0004444')
      allow(adapter).to receive(:findLeadGuestCard).with(linked_lead).and_return(guestcard)
      allow(adapter).to receive(:findLeadGuestCard).with(created_lead).and_return(nil)

      dry = described_class.new(dry_run: true)
      allow(dry).to receive(:sleep)
      result = dry.push_property(property)

      expect(result[:linked]).to eq(1)
      expect(result[:created]).to eq(1)
      # sendGuestCard is not stubbed here: a call would raise and count as an
      # error, so created=1 proves nothing was actually sent
      expect(linked_lead.reload.remoteid).to be_blank
      expect(created_lead.reload.remoteid).to be_blank
      expect(created_lead.referral).to eq('Zillow')
    end
  end

  describe '#call' do
    it 'skips when the advisory lock is held by another run' do
      allow(pusher).to receive(:with_advisory_lock).and_yield(false)

      results = pusher.call

      expect(results.first[:skipped]).to be_present
    end

    it 'processes active properties when the lock is acquired' do
      allow(pusher).to receive(:with_advisory_lock).and_yield(true)
      allow(adapter).to receive(:findLeadGuestCard).and_return(nil)

      results = pusher.call

      expect(results.map { |r| r[:property] }).to include(property.name)
    end
  end
end
