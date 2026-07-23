require 'rails_helper'

RSpec.describe MarketingSources::YardiSourceAudit do
  include_context 'users'

  let(:property) { create(:property) }
  let(:voyager_source) { create(:lead_source, slug: 'YardiVoyager', name: 'YardiVoyager2') }
  let(:phone_source) { create(:lead_source, slug: 'CallCenter', name: 'CallCenter2') }
  let(:voyager_code) { 'testcode' }
  let!(:property_listing) { create(:property_listing, property: property, source: voyager_source, code: voyager_code, active: true) }
  let(:adapter) { instance_double(Yardi::Voyager::Api::GuestCards) }
  let(:audit) { described_class.new }

  let!(:tracked_matching) {
    create(:marketing_source, property: property, name: 'Property Website',
           phone_lead_source: phone_source, tracking_number: '5555550001', destination_number: '5555550000')
  }
  let!(:tracked_missing) {
    create(:marketing_source, property: property, name: 'Zillow',
           phone_lead_source: phone_source, tracking_number: '5555550002', destination_number: '5555550000')
  }
  let!(:untracked) {
    create(:marketing_source, property: property, name: 'Some Web Source',
           lead_source: nil, phone_lead_source: nil, email_lead_source: nil,
           tracking_number: nil, tracking_email: nil, tracking_code: nil,
           destination_number: nil)
  }

  before do
    allow(Yardi::Voyager::Api::GuestCards).to receive(:new).and_return(adapter)
    # Never actually wait out the retry backoff in specs
    allow(audit).to receive(:sleep)
    ActiveJob::Base.queue_adapter = :test
  end

  describe '#audit_property' do
    it 'flags tracked sources whose name is not in Yardi and clears matches' do
      allow(adapter).to receive(:getMarketingSources).with(voyager_code).
        and_return(['Property Website', 'Bluesky'])

      result = audit.audit_property(property)

      expect(result[:missing]).to eq(['Zillow'])
      expect(tracked_matching.reload.yardi_source_missing).to be false
      expect(tracked_missing.reload.yardi_source_missing).to be true
      expect(untracked.reload.yardi_source_missing).to be false
      expect(tracked_missing.reload.yardi_source_checked_at).to be_present
    end

    it 'requires an exact 1:1 name match' do
      allow(adapter).to receive(:getMarketingSources).with(voyager_code).
        and_return(['property website', 'Zillow.com'])

      audit.audit_property(property)

      expect(tracked_matching.reload.yardi_source_missing).to be true
      expect(tracked_missing.reload.yardi_source_missing).to be true
    end

    it 'retries on API errors and leaves flags untouched after final failure' do
      tracked_missing.update_columns(yardi_source_missing: true)
      allow(adapter).to receive(:getMarketingSources).and_raise('Voyager unavailable')

      result = audit.audit_property(property)

      expect(adapter).to have_received(:getMarketingSources).
        exactly(described_class::MAX_ATTEMPTS).times
      expect(result[:error]).to be_present
      expect(tracked_missing.reload.yardi_source_missing).to be true
      expect(tracked_matching.reload.yardi_source_missing).to be false
    end

    it 'succeeds when a retry succeeds' do
      call_count = 0
      allow(adapter).to receive(:getMarketingSources) do
        call_count += 1
        raise 'Voyager unavailable' if call_count == 1
        ['Property Website', 'Zillow']
      end

      result = audit.audit_property(property)

      expect(result[:missing]).to eq([])
      expect(tracked_missing.reload.yardi_source_missing).to be false
    end

    it 'skips properties without a Voyager code' do
      property_listing.update(active: false)

      result = audit.audit_property(property)

      expect(result[:skipped]).to be_present
      expect(adapter).to_not receive(:getMarketingSources)
    end
  end

  describe '#call' do
    it 'audits all active properties when none is given' do
      allow(adapter).to receive(:getMarketingSources).and_return(['Property Website', 'Zillow'])

      results = audit.call

      expect(results).to be_an(Array)
      expect(results.map { |r| r[:property] }).to include(property.name)
    end
  end

  describe 'MarketingSource save trigger' do
    it 'enqueues an audit job when saving a source with a tracking number' do
      expect {
        tracked_matching.update(description: 'Updated')
      }.to have_enqueued_job(YardiSourceAuditJob).with(property.id)
    end

    it 'enqueues an audit job when the tracking number is removed' do
      expect {
        tracked_matching.update(phone_lead_source_id: nil)
      }.to have_enqueued_job(YardiSourceAuditJob).with(property.id)
    end

    it 'does not enqueue for sources without call tracking' do
      expect {
        untracked.update(description: 'Updated')
      }.to_not have_enqueued_job(YardiSourceAuditJob)
    end
  end
end
