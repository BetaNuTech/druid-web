require 'rails_helper'

RSpec.describe Leads::CallGuestcardBackfill do
  let(:call_center) { create(:lead_source, slug: 'CallCenter', name: 'CallCenter2') }
  let(:voyager_source) { create(:lead_source, slug: 'YardiVoyager', name: 'YardiVoyager2') }
  let(:property) { create(:property) }
  let!(:voyager_listing) { create(:property_listing, property: property, source: voyager_source, code: '1002edge', active: true) }

  let(:backup) do
    Class.new do
      attr_accessor :cards, :residents

      def initialize
        @cards = {}
        @residents = Set.new
      end

      def open
        yield self
      end

      def data_as_of = 30.minutes.ago
      def prospects_by_phone(_code, phones) = cards.slice(*phones)
      def resident_phones(_code, phones) = residents & phones
    end.new
  end

  # Leads created before the push went live have no queue entry
  def old_call(phone:, called:, state: 'open', referral: 'Google Business Profile', source: call_center)
    lead = create(:lead, property: property, source: source, state: 'open', user: nil,
                         phone1: phone, phone2: nil, referral: referral, first_name: 'Pat', last_name: 'Caller')
    lead.update_columns(created_at: called, state: state)
    lead.reload
  end

  def card(prospect_id, created_at:, source: 'Property Website', status: 'Prospect')
    Yardi::Backup::Database::Prospect.new(prospect_id: prospect_id, created_at: created_at, source: source, agent: 'Admin',
                                          created_by: 'leapro', status: status, first_name: 'Pat', last_name: 'Caller',
                                          relationship: nil)
  end

  describe '#candidates' do
    it 'takes open call leads from the window that are not queued yet' do
      wanted = old_call(phone: '6155550101', called: 3.days.ago)
      old_call(phone: '6155550102', called: 3.days.ago, state: 'invalidated')
      old_call(phone: '6155550103', called: 45.days.ago)
      old_call(phone: '6155550104', called: 3.days.ago, source: create(:lead_source, slug: 'Zillow'))
      queued = old_call(phone: '6155550105', called: 3.days.ago)
      CallGuestcardPush.create!(lead: queued, property: property, phone: '6155550105')

      expect(described_class.new(days: 30).candidates).to eq([wanted])
    end
  end

  describe 'dry run' do
    it 'simulates the pusher, including repeat-call chains, and changes nothing' do
      first = old_call(phone: '6155550201', called: 5.days.ago)
      repeat = old_call(phone: '6155550201', called: 4.days.ago) # within 48h of the first
      linked = old_call(phone: '6155550202', called: 10.days.ago)
      resident = old_call(phone: '6155550203', called: 20.days.ago)
      backup.cards['6155550202'] = [card('p0523371', created_at: linked.created_at + 2.minutes)]
      backup.residents << '6155550203'

      report = described_class.new(days: 30, dry_run: true, database: backup).call

      expect(report[:candidates]).to eq(4)
      expect(report[:decisions]).to eq('created' => 1, 'repeat_call' => 1, 'linked_new_card' => 1, 'resident' => 1)
      expect(report[:new_cards_by_age]).to eq('0-7 days' => 1)
      expect(report[:source_fixable]).to eq(1)
      expect(CallGuestcardPush.count).to eq(0)
      expect([first, repeat, linked, resident].map { |lead| lead.reload.state }.uniq).to eq(['open'])
    end

    it 'counts a call whose card another lead here already links as a duplicate' do
      earlier = old_call(phone: '6155550401', called: 9.days.ago)
      earlier.update_columns(remoteid: 'p0500001', state: 'prospect')
      old_call(phone: '6155550401', called: 3.days.ago)
      backup.cards['6155550401'] = [card('p0500001', created_at: 60.days.ago)]

      report = described_class.new(days: 30, dry_run: true, database: backup).call

      expect(report[:decisions]).to eq('duplicate_lead' => 1)
    end

    it 'treats a card created days after the call as an existing card, not the call’s own' do
      lead = old_call(phone: '6155550301', called: 6.days.ago)
      backup.cards['6155550301'] = [card('p0599999', created_at: lead.created_at + 3.days)]

      report = described_class.new(days: 30, dry_run: true, database: backup).call

      expect(report[:decisions]).to eq('linked_existing_card' => 1)
    end
  end

  describe 'real run' do
    it 'queues the candidates for the pusher' do
      lead = old_call(phone: '(615) 555-0401', called: 2.days.ago)

      expect(described_class.new(days: 30, dry_run: false).call).to eq(dry_run: false, queued: 1)
      expect(lead.reload.call_guestcard_push).to have_attributes(status: 'pending', phone: '6155550401',
                                                                 referral: 'Google Business Profile')
    end
  end
end
