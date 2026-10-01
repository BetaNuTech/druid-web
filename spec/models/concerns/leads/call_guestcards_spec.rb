require 'rails_helper'

RSpec.describe Leads::CallGuestcards do
  let(:call_center) { create(:lead_source, slug: 'CallCenter', name: 'CallCenter2') }
  let(:voyager_source) { create(:lead_source, slug: 'YardiVoyager', name: 'YardiVoyager2') }
  let(:property) { create(:property) }
  let!(:voyager_listing) { create(:property_listing, property: property, source: voyager_source, code: '1002edge', active: true) }
  let(:enabled_env) { Leads::CallGuestcardPusher::ENABLED_ENV }

  around do |example|
    saved = ENV[enabled_env]
    ENV[enabled_env] = 'true'
    example.run
  ensure
    saved.nil? ? ENV.delete(enabled_env) : ENV[enabled_env] = saved
  end

  def call_lead(**attributes)
    create(:lead, { property: property, source: call_center, state: 'open', user: nil,
                    phone1: '6155550123', referral: 'Google Business Profile' }.merge(attributes))
  end

  describe 'automated outreach' do
    it 'is suppressed for call leads while the push is enabled' do
      lead = call_lead
      expect(lead.automated_outreach_suppressed?).to be true
      expect(lead.send_new_lead_messaging).to be false
      expect(lead.request_sms_communication_authorization).to be false
    end

    it 'is not suppressed when the push is disabled' do
      lead = call_lead
      ENV[enabled_env] = 'false'
      expect(lead.automated_outreach_suppressed?).to be false
    end

    it 'is not suppressed for leads from other sources' do
      lead = create(:lead, property: property, source: create(:lead_source, slug: 'Zillow'), state: 'open')
      expect(lead.automated_outreach_suppressed?).to be false
    end

    it 'never attempts the SMS opt-in request or welcome email for a call lead' do
      lead = call_lead
      expect(lead).not_to receive(:request_first_sms_authorization_if_open_and_unique)
      expect(lead).not_to receive(:lead_automatic_reply)
      lead.send_new_lead_messaging
    end

    it 'attempts them as before when the push is disabled' do
      lead = call_lead
      ENV[enabled_env] = 'false'
      expect(lead).to receive(:request_first_sms_authorization_if_open_and_unique)
      expect(lead).to receive(:lead_automatic_reply)
      lead.send_new_lead_messaging
    end
  end

  describe 'the legacy Yardi sync' do
    let(:agent) { create(:user) }

    it 'never creates, updates or cancels guest cards for leads the push owns' do
      owned_new = call_lead
      owned_new.update_columns(state: 'prospect', user_id: agent.id)
      owned_new.call_guestcard_push.update_columns(status: 'linked_existing_card')

      owned_synced = call_lead(phone1: '6155550124')
      owned_synced.update_columns(state: 'prospect', user_id: User.system.id, remoteid: 'p0500001', updated_at: Time.current)
      owned_synced.call_guestcard_push.update_columns(status: 'created')

      owned_invalidated = call_lead(phone1: '6155550125')
      owned_invalidated.update_columns(state: 'invalidated', remoteid: 'p0500002', updated_at: Time.current)
      owned_invalidated.call_guestcard_push.update_columns(status: 'linked_existing_card')

      ordinary = create(:lead, property: property, source: create(:lead_source, slug: 'Zillow'), state: 'open')
      ordinary.update_columns(state: 'prospect', user_id: agent.id)

      expect(property.new_leads_for_sync).to include(ordinary)
      expect(property.new_leads_for_sync).not_to include(owned_new)
      expect(property.leads_for_sync).not_to include(owned_synced)
      expect(property.leads_for_cancelling).not_to include(owned_invalidated)
    end

    it 'still syncs a queued call lead the push has not resolved' do
      pending_lead = call_lead
      pending_lead.update_columns(state: 'prospect', user_id: agent.id)

      expect(property.new_leads_for_sync).to include(pending_lead)
    end
  end
end
