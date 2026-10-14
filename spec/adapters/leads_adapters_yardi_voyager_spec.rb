require 'rails_helper'

RSpec.describe Leads::Adapters::YardiVoyager do
  include_context "users"
  include_context "messaging"

  let(:property_code) { 'marble' }
  let(:property) { create(:property) }
  let(:lead_source) { create(:yardi_voyager_source)}
  let(:listing) { create(:property_listing, code: property_code, property: property, source: lead_source)}
  let(:initial_params) {
    listing
    property
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

    it "handles the creation of cancelled Guestcards/Future Leads" do
      guestcard = guestcards.select{|gc| gc.record_type = 'canceled'}.first
      updated_lead = adapter.send(:lead_from_guestcard, guestcard)
      assert updated_lead.new_record?
      assert updated_lead.valid?
      assert updated_lead.save
      expect( updated_lead.state ).to eq('future')
      expect( updated_lead.priority ).to eq('zero')
    end
  end

  describe "#createGuestCards" do
    let(:agent) { create(:user) }
    let(:guestcards_api) { double('Yardi::Voyager::Api::GuestCards', :debug= => nil) }
    let(:backup) do
      Class.new do
        attr_accessor :residents, :failure

        def initialize
          @residents = {}
        end

        def configured? = true
        def close; end

        def connect_with_retries(**)
          raise failure if failure

          self
        end

        def residents_by_contact(_code, phones:, emails: [])
          residents.slice(*(phones + emails))
        end
      end.new
    end
    let(:gate) { Leads::YardiResidentGate.new(database: backup) }
    let(:zoe) do
      Yardi::Backup::Database::Resident.new(tenant_code: 't0225446', prospect_code: 'p0518217', first_name: 'Zoe', last_name: 'Ellis',
                                            unit: '0406', status: 'notice', relationship: 'Tenant', phones: ['2562636836'])
    end

    def new_lead(phone1:, state: 'prospect')
      lead = create(:lead, property: property, state: 'open', user: nil, remoteid: nil, classification: nil, phone1: phone1,
                           first_name: 'Pat', last_name: 'Caller')
      lead.update_columns(state: state, user_id: agent.id)
      lead
    end

    before do
      manager
      allow(Yardi::Voyager::Api::GuestCards).to receive(:new).and_return(guestcards_api)
      allow(guestcards_api).to receive(:sendGuestCard) { |lead:, **| lead.remoteid = 'p0007777'; lead }
      Rails.cache.clear
    end

    it 'closes out residents and sends only the other leads' do
      resident_lead = new_lead(phone1: '2562636836')
      other = new_lead(phone1: '6155550123')
      backup.residents = { '2562636836' => [zoe] }

      sent = adapter.createGuestCards(start_date: 1.hour.ago, gate: gate)

      expect(sent).to eq([other])
      expect(other.reload.remoteid).to eq('p0007777')
      expect(resident_lead.reload).to have_attributes(state: 'invalidated', classification: 'resident', remoteid: nil)
      expect(adapter.last_screen[:residents].map(&:first)).to eq([resident_lead])
      expect(guestcards_api).to have_received(:sendGuestCard).once
    end

    it 'holds a matched lead the state machine cannot invalidate, with one note' do
      showing = new_lead(phone1: '2562636836', state: 'showing')
      backup.residents = { '2562636836' => [zoe] }

      expect(adapter.createGuestCards(start_date: 1.hour.ago, gate: gate)).to eq([])
      expect(showing.reload).to have_attributes(state: 'showing', remoteid: nil)
      expect(Note.where(notable: showing).where('content LIKE ?', 'Yardi sync: not sent to Yardi%').count).to eq(1)
      expect(guestcards_api).not_to have_received(:sendGuestCard)
    end

    it 'holds the creates while the backup is unavailable and widens the window until a run succeeds' do
      lead = new_lead(phone1: '6155550123')
      lead.update_columns(created_at: 2.hours.ago, updated_at: 2.hours.ago)
      backup.failure = Yardi::Backup::Database::Unavailable.new('restoring')
      allow(ErrorNotification).to receive(:send)

      expect(adapter.createGuestCards(start_date: 3.hours.ago, gate: gate)).to eq([])
      expect(adapter.last_screen).to include(held: 1)
      expect(lead.reload.remoteid).to be_nil
      expect(ErrorNotification).not_to have_received(:send)

      # The next run's window would miss the lead, but the hold widens it
      backup.failure = nil
      next_run_gate = Leads::YardiResidentGate.new(database: backup)
      expect(adapter.createGuestCards(start_date: 20.minutes.ago, gate: next_run_gate)).to eq([lead])
      expect(lead.reload.remoteid).to eq('p0007777')
      expect(Rails.cache.read(format(described_class::CREATE_HOLD_CACHE_KEY, property.id))).to be_nil
    end

    it 'screens but writes nothing when commit is off' do
      resident_lead = new_lead(phone1: '2562636836')
      backup.residents = { '2562636836' => [zoe] }
      allow(Leads::YardiResidentGate).to receive(:new).and_wrap_original { |original, **options| original.call(**options.merge(database: backup)) }
      adapter.commit = false

      adapter.createGuestCards(start_date: 1.hour.ago)

      expect(Leads::YardiResidentGate).to have_received(:new).with(dry_run: true)
      expect(adapter.last_screen[:residents].map(&:first)).to eq([resident_lead])
      expect(resident_lead.reload.state).to eq('prospect')
      expect(guestcards_api).not_to have_received(:sendGuestCard)
    end

    it 'does not re-select a lead already classified as a resident' do
      lead = new_lead(phone1: '6155550123')
      lead.update_columns(classification: Lead.classifications[:resident])

      expect(adapter.createGuestCards(start_date: 1.hour.ago, gate: gate)).to eq([])
      expect(guestcards_api).not_to have_received(:sendGuestCard)
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
