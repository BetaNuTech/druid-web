require 'rails_helper'

RSpec.describe OpenaiClient do
  let(:client) { described_class.new }
  let(:property) { create(:property, name: 'Test Property', address1: '123 Main St', city: 'City', state: 'ST', zip: '12345') }
  let(:lead_source) { create(:lead_source, name: 'Zillow') }
  let(:property_listing) { create(:property_listing, property: property, source: lead_source) }
  let(:active_sources) { [lead_source] }
  
  let(:email_content) {
    {
      headers: {
        'From' => 'john.doe@example.com',
        'To' => 'property+ABC123@cloudmailin.net',
        'Subject' => 'New Zillow Group Rentals Contact: Test Property',
        'Date' => '2025-06-10 16:39:50 UTC'
      },
      plain: 'John Doe is interested in Test Property. Phone: 555-123-4567, Email: john.doe@example.com'
    }
  }
  
  let(:successful_response) {
    {
      'choices' => [{
        'message' => {
          'content' => {
            'is_lead' => true,
            'lead_type' => 'rental_inquiry',
            'confidence' => 0.95,
            'source_match' => 'Zillow',
            'lead_data' => {
              'first_name' => 'John',
              'last_name' => 'Doe',
              'email' => 'john.doe@example.com',
              'phone1' => '555-123-4567',
              'phone2' => nil,
              'message' => 'Interested in Test Property',
              'preferred_move_in_date' => nil,
              'unit_type' => nil,
              'company' => nil
            },
            'classification_reason' => 'Email contains rental inquiry with contact information'
          }.to_json
        }
      }]
    }
  }
  
  let(:non_lead_response) {
    {
      'choices' => [{
        'message' => {
          'content' => {
            'is_lead' => false,
            'lead_type' => 'vendor',
            'confidence' => 0.85,
            'source_match' => nil,
            'lead_data' => {
              'first_name' => 'ABC',
              'last_name' => 'Plumbing',
              'email' => 'service@abcplumbing.com',
              'phone1' => '555-999-8888',
              'phone2' => nil,
              'message' => 'Invoice for plumbing services',
              'preferred_move_in_date' => nil,
              'unit_type' => nil,
              'company' => 'ABC Plumbing'
            },
            'classification_reason' => 'Email appears to be from a service vendor sending an invoice'
          }.to_json
        }
      }]
    }
  }
  
  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with('OPENAI_API_TOKEN').and_return('test-api-key')
    allow(ENV).to receive(:fetch).with('OPENAI_ORG', nil).and_return('test-org')
    allow(ENV).to receive(:fetch).with('OPENAI_MODEL', 'gpt-4o-mini').and_return('gpt-4o-mini')
    property_listing # ensure it exists
  end
  
  describe "#initialize" do
    it "loads configuration from environment variables" do
      expect(client.api_key).to eq('test-api-key')
      expect(client.organization).to eq('test-org')
      expect(client.model).to eq('gpt-4o-mini')
    end
    
    it "raises error when API token is not set" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('OPENAI_API_TOKEN').and_raise(KeyError, 'OPENAI_API_TOKEN not set')
      
      expect { described_class.new }.to raise_error(KeyError, 'OPENAI_API_TOKEN not set')
    end
  end
  
  describe "#analyze_email" do
    let(:http_response) { double('response', code: '200', body: successful_response.to_json) }
    let(:http) { double('http', request: http_response) }
    
    before do
      allow(Net::HTTP).to receive(:new).and_return(http)
      allow(http).to receive(:use_ssl=)
      allow(http).to receive(:read_timeout=)
      allow(http).to receive(:open_timeout=)
    end
    
    context "with successful response" do
      it "returns parsed lead data for a rental inquiry" do
        result = client.analyze_email(email_content, property, active_sources)
        
        expect(result).to be_a(Hash)
        expect(result['is_lead']).to be true
        expect(result['lead_type']).to eq('rental_inquiry')
        expect(result['confidence']).to eq(0.95)
        expect(result['source_match']).to eq('Zillow')
        expect(result['lead_data']['first_name']).to eq('John')
        expect(result['lead_data']['last_name']).to eq('Doe')
        expect(result['lead_data']['email']).to eq('john.doe@example.com')
        expect(result['lead_data']['phone1']).to eq('555-123-4567')
      end
      
      it "returns parsed data for non-lead emails" do
        allow(http).to receive(:request).and_return(
          double('response', code: '200', body: non_lead_response.to_json)
        )
        
        result = client.analyze_email(email_content, property, active_sources)
        
        expect(result['is_lead']).to be false
        expect(result['lead_type']).to eq('vendor')
        expect(result['lead_data']['first_name']).to eq('ABC')
        expect(result['lead_data']['last_name']).to eq('Plumbing')
        expect(result['classification_reason']).to include('service vendor')
      end
    end
    
    context "with API errors" do
      it "raises RateLimitError on 429 response" do
        allow(http).to receive(:request).and_return(
          double('response', code: '429', body: 'Rate limit exceeded')
        )
        
        expect {
          client.analyze_email(email_content, property, active_sources)
        }.to raise_error(OpenaiClient::RateLimitError, 'Rate limit exceeded')
      end
      
      it "raises ServiceUnavailableError on 503 response" do
        allow(http).to receive(:request).and_return(
          double('response', code: '503', body: 'Service unavailable')
        )
        
        expect {
          client.analyze_email(email_content, property, active_sources)
        }.to raise_error(OpenaiClient::ServiceUnavailableError, /service unavailable/)
      end
      
      it "retries on timeout errors" do
        call_count = 0
        allow(http).to receive(:request) do
          call_count += 1
          if call_count < 3
            raise Net::ReadTimeout
          else
            http_response
          end
        end
        
        expect(client).to receive(:sleep).twice
        
        result = client.analyze_email(email_content, property, active_sources)
        expect(result).to be_a(Hash)
      end
      
      it "raises error after max retries" do
        allow(http).to receive(:request).and_raise(Net::ReadTimeout)
        
        expect {
          client.analyze_email(email_content, property, active_sources)
        }.to raise_error(OpenaiClient::ServiceUnavailableError, /Timeout after 3 retries/)
      end
    end
    
    context "with circuit breaker" do
      it "opens circuit after service errors" do
        allow(http).to receive(:request).and_return(
          double('response', code: '503', body: 'Service unavailable')
        )
        
        # First call opens the circuit
        expect {
          client.analyze_email(email_content, property, active_sources)
        }.to raise_error(OpenaiClient::ServiceUnavailableError)
        
        # Second call should return nil immediately (circuit open)
        expect(client.analyze_email(email_content, property, active_sources)).to be_nil
      end
      
      it "closes circuit after cooldown period" do
        allow(http).to receive(:request).and_return(
          double('response', code: '503', body: 'Service unavailable')
        )
        
        # Open the circuit
        expect {
          client.analyze_email(email_content, property, active_sources)
        }.to raise_error(OpenaiClient::ServiceUnavailableError)
        
        # Fast forward time
        allow(Time).to receive(:current).and_return(Time.current + 301)
        
        # Circuit should be closed, request should be made again
        expect(http).to receive(:request).and_return(http_response)
        
        result = client.analyze_email(email_content, property, active_sources)
        expect(result).to be_a(Hash)
      end
    end
    
    context "with malformed responses" do
      it "returns nil for invalid JSON in response content" do
        allow(http).to receive(:request).and_return(
          double('response', code: '200', body: '{"choices":[{"message":{"content":"invalid json"}}]}')
        )
        
        result = client.analyze_email(email_content, property, active_sources)
        expect(result).to be_nil
      end
      
      it "returns nil for missing content in response" do
        allow(http).to receive(:request).and_return(
          double('response', code: '200', body: '{"choices":[]}')
        )
        
        result = client.analyze_email(email_content, property, active_sources)
        expect(result).to be_nil
      end
    end
  end
end