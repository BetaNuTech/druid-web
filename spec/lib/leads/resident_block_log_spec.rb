require 'rails_helper'

RSpec.describe Leads::ResidentBlockLog do
  include ActiveJob::TestHelper

  let(:property) { create(:property, name: 'Vintage Edge') }
  let(:yardi_resident) do
    Yardi::Backup::Database::Resident.new(tenant_code: 't0225446', prospect_code: 'p0518217', first_name: 'Zoe', last_name: 'Ellis',
                                          unit: '0406', status: 'notice', relationship: 'Tenant', phones: ['2562636836'])
  end

  around do |example|
    with_env(RESIDENT_BLOCK_SLACK_CHANNEL: '#bluesky-resident-blocks') { example.run }
  end

  it 'writes a property note and queues one Slack line as Yoda Bot, naming the tracking number called' do
    call_center = create(:lead_source, slug: 'CallCenter', name: 'CallCenter2')
    # update_columns: the model clears tracking numbers without a fully configured phone source
    create(:marketing_source, property: property, name: 'Google Business Profile').update_columns(tracking_number: '6155550100')
    text = nil
    expect do
      text = described_class.record(property: property, stage: 'rejected on arrival', resident: yardi_resident,
                                    contact: '+1 (256) 263-6836', source: call_center, referral: 'Google Business Profile')
    end.to have_enqueued_job(YodaBotMessageJob).with(channel: '#bluesky-resident-blocks',
                                                      text: 'Vintage Edge: BlueConnect call to (615) 555-0100 (Google Business Profile), ' \
                                                            'from (256) 263-6836, rejected on arrival, ' \
                                                            'matches resident Zoe Ellis, unit 0406, notice (Tenant t0225446)')

    expect(text).to eq('BlueConnect call to (615) 555-0100 (Google Business Profile), from (256) 263-6836, rejected on arrival, ' \
                       'matches resident Zoe Ellis, unit 0406, notice (Tenant t0225446)')
    note = Note.where(notable: property).last
    expect(note.classification).to eq('system')
    expect(note.content).to eq("Resident block: #{text}")
  end

  it 'describes a local resident row the same way' do
    resident = create(:resident, property: property, residentid: 't0225115-p0514945', first_name: 'Roscoe', last_name: 'Grant',
                                 relationship: 'Roommate', yardi_status: 'current', status: 'current')
    lead = create(:lead, property: property, phone1: '6159455943')

    text = described_class.record(property: property, stage: 'closed after creation', resident: resident, contact: lead.email,
                                  lead: lead, source: 'Zillow', referral: 'Zillow')

    expect(text).to eq("Zillow contact to Zillow, from #{lead.email} (Lead #{lead.id}), closed after creation, matches resident " \
                       "#{resident.name}, unit #{resident.unit.unit}, current (Roommate t0225115-p0514945)")
  end

  it 'skips Slack without a channel and never raises' do
    with_env(RESIDENT_BLOCK_SLACK_CHANNEL: nil) do
      expect { described_class.record(property: property, stage: 'rejected on arrival', resident: 'someone') }
        .not_to have_enqueued_job(YodaBotMessageJob)
    end
    allow(Note).to receive(:create).and_raise('db down')
    expect(described_class.record(property: property, stage: 'rejected on arrival', resident: 'someone')).to be_nil
  end
end
