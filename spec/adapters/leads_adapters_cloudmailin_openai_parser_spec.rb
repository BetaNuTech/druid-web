require 'rails_helper'

RSpec.describe Leads::Adapters::CloudMailin::OpenaiParser do
  
  describe ".match?" do
    it "returns true when ENABLE_OPENAI_PARSER is set to true" do
      allow(ENV).to receive(:fetch).with('ENABLE_OPENAI_PARSER', 'false').and_return('true')
      expect(described_class.match?({})).to be true
    end
    
    it "returns false when ENABLE_OPENAI_PARSER is set to false" do
      allow(ENV).to receive(:fetch).with('ENABLE_OPENAI_PARSER', 'false').and_return('false')
      expect(described_class.match?({})).to be false
    end
    
    it "returns false when ENABLE_OPENAI_PARSER is not set" do
      allow(ENV).to receive(:fetch).with('ENABLE_OPENAI_PARSER', 'false').and_return('false')
      expect(described_class.match?({})).to be false
    end
  end
  
  describe ".parse" do
    let(:email_data) {
      {
        headers: {
          'From' => 'john.doe@example.com',
          'To' => 'property+ABC123@cloudmailin.net',
          'Subject' => 'Inquiry about 2BR apartment'
        },
        envelope: {
          from: 'john.doe@example.com',
          to: 'property+ABC123@cloudmailin.net'
        },
        plain: 'I am interested in your 2BR apartment.',
        html: '<p>I am interested in your 2BR apartment.</p>'
      }
    }
    
    let(:email_with_angled_brackets) {
      email_data.merge(
        headers: email_data[:headers].merge('From' => 'John Doe <john.doe@example.com>')
      )
    }
    
    it "returns minimal lead data for async processing" do
      result = described_class.parse(email_data)
      
      expect(result[:first_name]).to eq('Processing')
      expect(result[:last_name]).to eq('Via AI')
      expect(result[:email]).to eq('john.doe@example.com')
      expect(result[:phone1]).to be_nil
      expect(result[:preference_attributes][:notes]).to include('being processed by AI')
      expect(result[:preference_attributes][:raw_data]).to eq(email_data.to_json)
    end
    
    it "extracts email from angled bracket format" do
      result = described_class.parse(email_with_angled_brackets)
      
      expect(result[:email]).to eq('john.doe@example.com')
    end
    
    it "handles missing email gracefully" do
      data = email_data.deep_dup
      data[:headers].delete('From')
      data[:envelope].delete(:from)
      
      result = described_class.parse(data)
      
      expect(result[:email]).to be_nil
    end
    
    it "preserves raw data for async processing" do
      result = described_class.parse(email_data)
      
      expect(result[:preference_attributes][:raw_data]).to include('headers', 'envelope', 'plain', 'html')
    end
  end
end