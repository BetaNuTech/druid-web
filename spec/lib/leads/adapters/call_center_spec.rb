require 'rails_helper'

RSpec.describe Leads::Adapters::CallCenter do
  let(:property) { create(:property) }
  let(:lead_params) do
    {
      property_id: property.id,
      first_name: 'John',
      last_name: 'Doe',
      phone1: '5551234567'
    }
  end

  let(:twilio_sid) { "AC#{'0' * 32}" }
  let(:twilio_token) { 'test_token' }
  let(:captured_requests) { [] }
  # Realistic Twilio Lookups v1 caller-name response payload
  let(:lookup_payload) do
    {
      'caller_name' => {
        'caller_name' => 'JANE SMITH',
        'caller_type' => 'CONSUMER',
        'error_code' => nil
      },
      'carrier' => nil,
      'country_code' => 'US',
      'national_format' => '(555) 123-4567',
      'phone_number' => '+15551234567',
      'add_ons' => nil,
      'url' => 'https://lookups.twilio.com/v1/PhoneNumbers/+15551234567?Type=caller-name'
    }
  end

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('MESSAGE_DELIVERY_TWILIO_SID', '').and_return(twilio_sid)
    allow(ENV).to receive(:fetch).with('MESSAGE_DELIVERY_TWILIO_TOKEN', '').and_return(twilio_token)
    # Stub the HTTP boundary only, so the real twilio-ruby lookup chain
    # (client.lookups.v1.phone_numbers(...).fetch) runs and API surface
    # changes are caught by this spec.
    allow_any_instance_of(Twilio::REST::Client).to receive(:request) do |_client, *args, **kwargs|
      captured_requests << { args: args, kwargs: kwargs }
      Twilio::Response.new(200, lookup_payload.to_json)
    end
  end

  describe '#parse' do
    context 'when a name is provided' do
      it 'returns an :ok result with the provided name' do
        result = described_class.new(lead_params).parse

        expect(result).to be_a(Leads::Creator::Result)
        expect(result.status).to eq(:ok)
        expect(result.property_code).to eq(property.id)
        expect(result.lead['first_name']).to eq('John')
        expect(result.lead['last_name']).to eq('Doe')
      end

      it 'does not call the Twilio Lookup API' do
        described_class.new(lead_params).parse
        expect(captured_requests).to be_empty
      end
    end

    context 'when the caller name is Unknown' do
      let(:unknown_caller_params) { lead_params.merge(first_name: 'Unknown', last_name: nil) }

      it 'fetches the caller name from the Twilio Lookup API' do
        result = described_class.new(unknown_caller_params).parse

        expect(result.status).to eq(:ok)
        expect(result.lead['first_name']).to eq('JANE')
        expect(result.lead['last_name']).to eq('SMITH')

        expect(captured_requests.size).to eq(1)
        request_values = captured_requests.first[:args] + captured_requests.first[:kwargs].values
        uri = request_values.find { |value| value.is_a?(String) && value.include?('PhoneNumbers') }
        expect(uri).to be_present
        expect(uri).to include('PhoneNumbers/15551234567')
      end

      it 'records a note about the billable API call' do
        expect {
          described_class.new(unknown_caller_params).parse
        }.to change { Note.count }.by(1)
      end

      it 'falls back to Unknown when the Twilio Lookup API fails' do
        allow_any_instance_of(Twilio::REST::Client).to receive(:request).
          and_raise(StandardError.new('connection failed'))

        result = described_class.new(unknown_caller_params).parse

        expect(result.lead['first_name']).to eq('Unknown')
      end
    end

    context 'with invalid lead data' do
      it 'returns an :invalid result when contact info is missing' do
        result = described_class.new(property_id: property.id, first_name: 'John').parse

        expect(result.status).to eq(:invalid)
        expect(result.errors).to be_present
      end
    end
  end
end
