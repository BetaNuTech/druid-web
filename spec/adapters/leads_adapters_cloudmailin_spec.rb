require 'rails_helper'

RSpec.describe Leads::Adapters::Cloudmailin do
  let(:property) { create(:property) }
  let(:cloudmailin_source) { create(:lead_source, slug: 'Cloudmailin') }
  let(:property_listing) { create(:property_listing, property: property, source: cloudmailin_source, code: property.id) }
  
  let(:email_params) {
    {
      headers: {
        'From' => 'john.doe@example.com',
        'To' => "property+#{property.id}@cloudmailin.net",
        'Subject' => 'Inquiry about apartment'
      },
      envelope: {
        from: 'john.doe@example.com',
        to: "property+#{property.id}@cloudmailin.net"
      },
      plain: 'I am interested in your apartment.',
      html: '<p>I am interested in your apartment.</p>'
    }
  }
  
  before do
    property_listing
  end
  
  describe "#parse" do
    context "when OpenAI parser is disabled" do
      before do
        allow(ENV).to receive(:fetch).with('ENABLE_OPENAI_PARSER', 'false').and_return('false')
      end
      
      it "uses traditional parser to create lead data" do
        adapter = described_class.new(email_params)
        result = adapter.parse
        
        expect(result).to be_a(Leads::Creator::Result)
        expect(result.status).not_to eq(:async_processing)
        expect(result.lead).to be_present
      end
    end
    
    context "when OpenAI parser is enabled" do
      before do
        allow(ENV).to receive(:fetch).with('ENABLE_OPENAI_PARSER', 'false').and_return('true')
      end
      
      it "stores raw email and returns async_processing status" do
        expect(CloudmailinRawEmail).to receive(:create_from_params)
          .with(email_params, property.id.to_s)
          .and_return(create(:cloudmailin_raw_email))
        
        expect(ProcessCloudmailinEmailJob).to receive(:perform_later)
        
        adapter = described_class.new(email_params)
        result = adapter.parse
        
        expect(result).to be_a(Leads::Creator::Result)
        expect(result.status).to eq(:async_processing)
        expect(result.lead).to eq({})  # Empty lead data
        expect(result.parser).to eq('OpenAI (Async)')
      end
      
      it "does not create a placeholder lead" do
        allow(CloudmailinRawEmail).to receive(:create_from_params)
          .and_return(create(:cloudmailin_raw_email))
        allow(ProcessCloudmailinEmailJob).to receive(:perform_later)
        
        adapter = described_class.new(email_params)
        result = adapter.parse
        
        # The result should have empty lead data to prevent lead creation
        expect(result.lead).to eq({})
        expect(result.lead[:first_name]).to be_nil
        expect(result.lead[:last_name]).to be_nil
      end
    end
    
    context "with exception list match" do
      let(:spam_params) {
        email_params.merge(
          plain: 'SPAM CONTENT SPAM CONTENT'
        )
      }
      
      before do
        allow(ENV).to receive(:fetch).with('ENABLE_OPENAI_PARSER', 'false').and_return('false')
        stub_const('Leads::Adapters::CloudMailin::ContentExceptionList::REJECT', ['SPAM CONTENT'])
      end
      
      it "returns nonlead status" do
        adapter = described_class.new(spam_params)
        result = adapter.parse
        
        expect(result.status).to eq(:nonlead)
        expect(result.errors).to include(/Email exception list match/)
      end
    end
  end
  
  describe "#get_property_code" do
    it "extracts property code from email address" do
      adapter = described_class.new(email_params)
      expect(adapter.send(:get_property_code, email_params)).to eq(property.id.to_s)
    end
    
    it "handles missing envelope data" do
      params = email_params.except(:envelope)
      adapter = described_class.new(params)
      expect(adapter.send(:get_property_code, params)).to be_nil
    end
  end
end