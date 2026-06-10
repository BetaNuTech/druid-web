require 'rails_helper'

RSpec.describe Messages::DeliveryAdapters::TwilioAdapter do
  include_context "messaging"

  let(:twilio_sid) { "AC#{'0' * 32}" }
  let(:twilio_token) { 'test_token' }
  let(:twilio_phone) { '5550000000' }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('MESSAGE_DELIVERY_TWILIO_SID', '').and_return(twilio_sid)
    allow(ENV).to receive(:fetch).with('MESSAGE_DELIVERY_TWILIO_TOKEN', '').and_return(twilio_token)
    allow(ENV).to receive(:fetch).with('MESSAGE_DELIVERY_TWILIO_PHONE', '').and_return(twilio_phone)
  end

  describe '#base_senderid' do
    it 'returns the configured Twilio phone number' do
      expect(described_class.new.base_senderid).to eq(twilio_phone)
    end
  end

  describe '#deliver' do
    let(:adapter) { described_class.new }

    context 'in the test environment' do
      it 'refuses to deliver and reports success' do
        result = adapter.deliver(to: '5551234567', body: 'Hello')
        expect(result[:success]).to be true
        expect(result[:log]).to match(/skipped in test/)
      end

      it 'does not contact the Twilio API' do
        expect_any_instance_of(Twilio::REST::Client).not_to receive(:request)
        adapter.deliver(to: '5551234567', body: 'Hello')
      end
    end

    context 'outside the test environment' do
      # Realistic Twilio Messages create response payload
      let(:twilio_message_payload) do
        {
          'sid' => "SM#{'0' * 32}",
          'account_sid' => twilio_sid,
          'from' => '+15550000000',
          'to' => '+15551234567',
          'body' => 'Hello from BlueSky',
          'status' => 'queued',
          'num_segments' => '1',
          'num_media' => '0',
          'direction' => 'outbound-api',
          'api_version' => '2010-04-01',
          'price' => nil,
          'price_unit' => 'USD',
          'error_code' => nil,
          'error_message' => nil,
          'date_created' => 'Tue, 09 Jun 2026 00:00:00 +0000',
          'date_updated' => 'Tue, 09 Jun 2026 00:00:00 +0000',
          'date_sent' => nil,
          'messaging_service_sid' => nil,
          'uri' => "/2010-04-01/Accounts/#{twilio_sid}/Messages/SM#{'0' * 32}.json",
          'subresource_uris' => {}
        }
      end
      let(:captured_requests) { [] }

      before do
        allow(Rails.env).to receive(:test?).and_return(false)
        # Stub the HTTP boundary only, so the real twilio-ruby request-building
        # code runs and API surface changes are caught by this spec.
        allow_any_instance_of(Twilio::REST::Client).to receive(:request) do |_client, *args, **kwargs|
          captured_requests << { args: args, kwargs: kwargs }
          Twilio::Response.new(201, twilio_message_payload.to_json)
        end
      end

      it 'sends the SMS through the Twilio REST API with formatted phone numbers' do
        result = adapter.deliver(to: '(555) 123-4567', body: 'Hello from BlueSky')

        expect(result[:success]).to be true
        expect(result[:log]).to match(/successfully delivered via Twilio/)

        expect(captured_requests.size).to eq(1)
        request_values = captured_requests.first[:args] + captured_requests.first[:kwargs].values

        uri = request_values.find { |value| value.is_a?(String) && value.include?('Messages.json') }
        expect(uri).to be_present
        expect(uri).to include("/Accounts/#{twilio_sid}/Messages.json")

        payload = request_values.find { |value| value.is_a?(Hash) && value.key?('From') }
        expect(payload).to be_present
        expect(payload['From']).to eq('+15550000000')
        expect(payload['To']).to eq('+15551234567')
        expect(payload['Body']).to eq('Hello from BlueSky')
      end

      it 'returns a failure result when the Twilio API raises an error' do
        allow_any_instance_of(Twilio::REST::Client).to receive(:request).
          and_raise(StandardError.new('connection failed'))

        result = adapter.deliver(to: '5551234567', body: 'Hello')

        expect(result[:success]).to be false
        expect(result[:log]).to match(/Twilio delivery failed: connection failed/)
      end
    end
  end

  describe '#parse' do
    let(:lead_phone) { '+15551234567' }
    let(:incoming_params) do
      {
        'From' => lead_phone,
        'To' => '+15550000000',
        'Body' => 'I would like to schedule a tour'
      }
    end

    context 'when the sender has an existing message thread' do
      let!(:previous_message) do
        create(:message,
               state: 'sent',
               recipientid: lead_phone,
               message_type: sms_message_type,
               threadid: Message.new_threadid)
      end

      it 'returns an :ok result with message data linked to the prior thread' do
        result = described_class.new(incoming_params).parse

        expect(result).to be_a(Messages::Receiver::Result)
        expect(result.status).to eq(:ok)
        expect(result.message[:senderid]).to eq(lead_phone)
        expect(result.message[:recipientid]).to eq('+15550000000')
        expect(result.message[:body]).to eq('I would like to schedule a tour')
        expect(result.message[:threadid]).to eq(previous_message.threadid)
        expect(result.message[:user_id]).to eq(previous_message.user_id)
        expect(result.message[:messageable_id]).to eq(previous_message.messageable_id)
      end
    end

    context 'when the sender is unknown' do
      it 'returns an :invalid result' do
        result = described_class.new(incoming_params).parse

        expect(result.status).to eq(:invalid)
        expect(result.errors).to be_present
      end
    end
  end

  describe '.response_for' do
    it 'returns an empty XML response for a valid message' do
      message = instance_double(Message, valid?: true)
      response = described_class.response_for(message)
      expect(response[:status]).to eq(:created)
      expect(response[:format]).to eq(:xml)
      expect(response[:body]).to eq('')
    end

    it 'returns an explanatory body for an invalid message' do
      message = instance_double(Message, valid?: false)
      response = described_class.response_for(message)
      expect(response[:status]).to eq(:created)
      expect(response[:body]).to match(/don't know how to route/)
    end
  end
end
