require 'rails_helper'

RSpec.describe Leads::CallGuestcardPusher do
  let(:call_center) { create(:lead_source, slug: 'CallCenter', name: 'CallCenter2') }
  let(:voyager_source) { create(:lead_source, slug: 'YardiVoyager', name: 'YardiVoyager2') }
  let(:property) { create(:property) }
  let!(:voyager_listing) { create(:property_listing, property: property, source: voyager_source, code: '1002edge', active: true) }
  let(:phone) { '6155550123' }

  # Stands in for Yardi::Backup::Database
  let(:backup) do
    Class.new do
      attr_accessor :as_of, :cards, :residents, :by_id, :shared_ids

      def initialize
        @cards = {}
        @residents = Set.new
        @by_id = {}
        @shared_ids = Set.new
      end

      def open
        yield self
      end

      def data_as_of = as_of
      def prospects_by_phone(_code, _phones) = cards
      def resident_phones(_code, _phones) = residents
      def prospect(_code, prospect_id) = by_id[prospect_id]
      def prospect_id_shared?(prospect_id) = shared_ids.include?(prospect_id)
    end.new.tap { |db| db.as_of = 10.minutes.ago }
  end

  let(:api) do
    double('Yardi::Voyager::Api::GuestCards').tap do |api|
      allow(api).to receive(:sendGuestCard) { |lead:, **| lead.remoteid = 'p0999001'; lead }
      allow(api).to receive(:sendSourceCorrection) { |prospect:, **| prospect.prospect_id }
    end
  end

  let(:pusher) { described_class.new(database: backup, api: api) }

  around do |example|
    keys = [described_class::ENABLED_ENV, described_class::FIX_SOURCE_ENV, described_class::HOLD_MINUTES_ENV]
    saved = keys.to_h { |key| [key, ENV[key]] }
    ENV[described_class::ENABLED_ENV] = 'true'
    ENV.delete(described_class::FIX_SOURCE_ENV)
    ENV.delete(described_class::HOLD_MINUTES_ENV)
    example.run
  ensure
    saved.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  def call_lead(phone: self.phone, referral: 'Google Business Profile', called: 2.hours.ago)
    lead = create(:lead, property: property, source: call_center, state: 'open', user: nil,
                         phone1: phone, phone2: nil, referral: referral, first_name: 'Pat', last_name: 'Caller')
    lead.update_columns(created_at: called)
    lead.reload
  end

  def card(prospect_id, created_at:, source: 'Property Website', status: 'Prospect', created_by: 'leapro')
    Yardi::Backup::Database::Prospect.new(prospect_id: prospect_id, created_at: created_at, source: source,
                                          agent: 'Admin', created_by: created_by, status: status,
                                          first_name: 'Pat', last_name: 'Caller', relationship: nil)
  end

  describe '.decide' do
    let(:called_at) { Time.zone.parse('2026-09-28 15:00') }

    it 'treats a caller already resolved within 48 hours as a repeat call first' do
      expect(described_class.decide(called_at: called_at, cards: [], resident: true, prior_prospect_id: 'p1').first).to eq(:repeat_call)
    end

    it 'checks residents before guest cards' do
      cards = [card('p1', created_at: called_at - 30.days)]
      expect(described_class.decide(called_at: called_at, cards: cards, resident: true).first).to eq(:resident)
    end

    it 'creates when there is no card' do
      expect(described_class.decide(called_at: called_at, cards: [], resident: false)).to eq([:create, nil])
    end

    it 'links a card made for this call, including one Lea made while the call was in progress' do
      lea_card = card('p2', created_at: called_at - 8.minutes)
      older = card('p1', created_at: called_at - 30.days)
      expect(described_class.decide(called_at: called_at, cards: [older, lea_card], resident: false)).to eq([:link_new_card, lea_card])
    end

    it 'does not count a card created more than two hours after the call as the call’s own' do
      later = card('p3', created_at: called_at + 3.hours)
      expect(described_class.decide(called_at: called_at, cards: [later], resident: false)).to eq([:link_existing_card, later])
    end

    it 'links the newest primary card when the caller already had one' do
      oldest = card('p1', created_at: called_at - 90.days)
      newest = card('p2', created_at: called_at - 10.days)
      expect(described_class.decide(called_at: called_at, cards: [oldest, newest], resident: false)).to eq([:link_existing_card, newest])
    end
  end

  describe 'queueing (Leads::CallGuestcards)' do
    it 'queues call leads with a normalized phone while enabled' do
      lead = call_lead(phone: '(615) 555-0123')
      expect(lead.call_guestcard_push).to have_attributes(status: 'pending', phone: '6155550123',
                                                          referral: 'Google Business Profile', property_id: property.id)
    end

    it 'does not queue while disabled' do
      ENV[described_class::ENABLED_ENV] = 'false'
      expect(call_lead.call_guestcard_push).to be_nil
    end

    it 'does not queue leads from other sources' do
      lead = create(:lead, property: property, source: create(:lead_source, slug: 'Zillow'), state: 'open')
      expect(lead.call_guestcard_push).to be_nil
    end

    it 'does not queue leads for a property without a Voyager code' do
      voyager_listing.update!(active: false)
      expect(call_lead.call_guestcard_push).to be_nil
    end
  end

  describe '#call' do
    it 'waits until the backup covers the call plus the hold time' do
      lead = call_lead(called: 20.minutes.ago)
      backup.as_of = 10.minutes.ago # covers only up to 5 minutes after the call

      summary = pusher.call

      expect(summary).to include(queued: 1, waiting: 1)
      expect(lead.call_guestcard_push.reload.status).to eq('pending')
      expect(api).not_to have_received(:sendGuestCard)
    end

    it 'creates an Admin guest card for a caller with no card, and hands the lead to the system user' do
      lead = call_lead

      summary = pusher.call

      expect(summary[:outcomes]).to eq('created' => 1)
      expect(api).to have_received(:sendGuestCard) do |lead:, agent:, include_events:, first_contact_comment:|
        expect(agent.profile.first_name).to eq('Admin')
        expect(include_events).to be true
        expect(first_contact_comment).to include('Google Business Profile tracking number')
      end
      lead.reload
      expect(lead).to have_attributes(state: 'prospect', remoteid: 'p0999001', user: User.system)
      expect(lead.call_guestcard_push).to have_attributes(status: 'created', yardi_prospect_id: 'p0999001')
      expect(lead.comments.pluck(:content)).to include(a_string_including('Pushed to Yardi as guest card p0999001'))
    end

    it 'links the card Lea made for the call instead of creating another' do
      lead = call_lead
      backup.cards = { phone => [card('p0523371', created_at: lead.created_at + 2.minutes)] }

      expect(pusher.call[:outcomes]).to eq('linked_new_card' => 1)
      expect(api).not_to have_received(:sendGuestCard)
      expect(lead.reload).to have_attributes(state: 'prospect', remoteid: 'p0523371', user: User.system)
      expect(lead.call_guestcard_push).to have_attributes(status: 'linked_new_card', yardi_source: 'Property Website',
                                                          source_fix_status: nil)
      expect(api).not_to have_received(:sendSourceCorrection)
    end

    it 'links an existing card without changing it' do
      lead = call_lead
      backup.cards = { phone => [card('p0500001', created_at: 40.days.ago, source: 'Zillow', created_by: 'egarcia')] }
      ENV[described_class::FIX_SOURCE_ENV] = 'true'

      expect(described_class.new(database: backup, api: api).call[:outcomes]).to eq('linked_existing_card' => 1)
      expect(lead.reload.remoteid).to eq('p0500001')
      expect(api).not_to have_received(:sendSourceCorrection)
    end

    context 'when source correction is enabled' do
      before { ENV[described_class::FIX_SOURCE_ENV] = 'true' }

      it "corrects the source on the call's own card" do
        lead = call_lead
        backup.cards = { phone => [card('p0523371', created_at: lead.created_at + 2.minutes)] }

        described_class.new(database: backup, api: api).call

        expect(api).to have_received(:sendSourceCorrection).with(hash_including(source: 'Google Business Profile', propertyid: '1002edge'))
        expect(lead.call_guestcard_push.reload.source_fix_status).to eq('sent')
      end

      it 'never updates a card whose ProspectID another card shares' do
        lead = call_lead
        backup.cards = { phone => [card('p0522900', created_at: lead.created_at + 2.minutes)] }
        backup.shared_ids << 'p0522900'

        described_class.new(database: backup, api: api).call

        expect(api).not_to have_received(:sendSourceCorrection)
        expect(lead.call_guestcard_push.reload.source_fix_status).to eq('skipped_shared_id')
      end

      it 'leaves a card Lea has already canceled alone' do
        lead = call_lead
        backup.cards = { phone => [card('p0523371', created_at: lead.created_at + 2.minutes, status: 'Canceled Guest')] }

        described_class.new(database: backup, api: api).call

        expect(api).not_to have_received(:sendSourceCorrection)
        expect(lead.call_guestcard_push.reload.source_fix_status).to eq('skipped_status')
      end
    end

    it 'invalidates a repeat call within 48 hours as a duplicate, creating only one card' do
      # Bluesky's own auto-dedupe may close the second call on create; this
      # covers the pusher's check, which is what catches repeats once the
      # first call belongs to the system user (exempt from auto-dedupe).
      allow(Flipflop).to receive(:enabled?).and_call_original
      allow(Flipflop).to receive(:enabled?).with(:lead_automatic_dedupe).and_return(false)
      first = call_lead(called: 3.hours.ago)
      second = call_lead(called: 2.hours.ago)

      expect(pusher.call[:outcomes]).to eq('created' => 1, 'repeat_call' => 1)
      expect(api).to have_received(:sendGuestCard).once
      expect(first.reload.state).to eq('prospect')
      expect(second.reload).to have_attributes(state: 'invalidated', classification: 'duplicate')
      expect(second.call_guestcard_push).to have_attributes(status: 'repeat_call', yardi_prospect_id: 'p0999001')
    end

    it 'closes a later call as a duplicate when another lead here already links the card' do
      earlier = create(:lead, property: property, source: create(:lead_source, slug: 'Zillow'), state: 'open')
      earlier.update_columns(remoteid: 'p0500001', state: 'prospect')
      lead = call_lead
      backup.cards = { phone => [card('p0500001', created_at: 40.days.ago)] }

      expect(pusher.call[:outcomes]).to eq('duplicate_lead' => 1)
      expect(lead.reload).to have_attributes(state: 'invalidated', classification: 'duplicate', remoteid: nil)
      expect(lead.call_guestcard_push.yardi_prospect_id).to eq('p0500001')
    end

    it 'links normally when only a lead at another property has the same Yardi ID' do
      other = create(:lead, property: create(:property), source: create(:lead_source, slug: 'Zillow'), state: 'open')
      other.update_columns(remoteid: 'p0500001') # Yardi reuses ProspectIDs across properties
      lead = call_lead
      backup.cards = { phone => [card('p0500001', created_at: 40.days.ago)] }

      expect(pusher.call[:outcomes]).to eq('linked_existing_card' => 1)
      expect(lead.reload).to have_attributes(state: 'prospect', user: User.system, remoteid: 'p0500001')
    end

    it 'keeps a new card whose ID Yardi reused at this property on the queue entry only' do
      other = create(:lead, property: property, source: create(:lead_source, slug: 'Zillow'), state: 'open')
      other.update_columns(remoteid: 'p0999001', state: 'invalidated') # the ID the fake API hands back
      lead = call_lead

      expect(pusher.call[:outcomes]).to eq('created' => 1)
      expect(lead.reload).to have_attributes(state: 'prospect', remoteid: nil)
      expect(lead.call_guestcard_push.yardi_prospect_id).to eq('p0999001')
    end

    it 'invalidates a call from a current resident' do
      lead = call_lead
      backup.residents = Set[phone]

      expect(pusher.call[:outcomes]).to eq('resident' => 1)
      expect(lead.reload).to have_attributes(state: 'invalidated', classification: 'resident')
      expect(api).not_to have_received(:sendGuestCard)
    end

    it 'skips a lead Bluesky already closed' do
      lead = call_lead
      lead.update_columns(state: 'invalidated')

      expect(pusher.call[:outcomes]).to eq('skipped_not_open' => 1)
      expect(api).not_to have_received(:sendGuestCard)
    end

    it 'retries a failed push only after the backup covers the attempt, then gives up' do
      allow(api).to receive(:sendGuestCard) { |lead:, **| lead } # no guest card id returned
      lead = call_lead
      push = lead.call_guestcard_push

      expect(pusher.call[:outcomes]).to eq('retry' => 1)
      expect(push.reload).to have_attributes(status: 'pending', attempts: 1, last_error: a_string_including('did not return'))

      # The backup does not yet show what the failed attempt may have created
      expect(pusher.call).to include(waiting: 1)

      push.update_columns(attempts: described_class::MAX_ATTEMPTS - 1, updated_at: 1.hour.ago)
      expect(pusher.call[:outcomes]).to eq('failed' => 1)
      expect(push.reload.status).to eq('failed')
      expect(lead.reload.state).to eq('open')
      expect(lead.comments.pluck(:content)).to include(a_string_including('gave up'))
    end

    it 'finishes adopting a card created on an earlier attempt without creating another' do
      lead = call_lead
      lead.call_guestcard_push.update_columns(yardi_prospect_id: 'p0888001')

      expect(pusher.call[:outcomes]).to eq('created' => 1)
      expect(api).not_to have_received(:sendGuestCard)
      expect(lead.reload.remoteid).to eq('p0888001')
    end

    it 'changes nothing in a dry run' do
      lead = call_lead

      summary = described_class.new(dry_run: true, database: backup, api: api).call

      expect(summary).to include(dry_run: true)
      expect(summary[:outcomes]).to eq('created' => 1)
      expect(api).not_to have_received(:sendGuestCard)
      expect(lead.reload.state).to eq('open')
      expect(lead.call_guestcard_push.status).to eq('pending')
    end
  end

  describe '#fix_source_for' do
    it 'corrects one linked lead regardless of the switch' do
      lead = call_lead
      push = lead.call_guestcard_push
      push.update_columns(status: 'linked_new_card', yardi_prospect_id: 'p0523371')
      backup.by_id['p0523371'] = card('p0523371', created_at: lead.created_at + 2.minutes)

      expect(pusher.fix_source_for(push)).to eq('sent')
      expect(push.reload).to have_attributes(source_fix_status: 'sent', yardi_source: 'Property Website')
    end
  end
end
