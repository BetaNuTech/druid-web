require 'rails_helper'

RSpec.describe Leads::Creator do
  let(:property) { create(:property) }
  let(:lead_source) { create(:lead_source, slug: 'Cloudmailin') }
  let(:property_listing) { create(:property_listing, property: property, source: lead_source, code: property.id) }
  
  let(:valid_lead_data) {
    {
      first_name: 'John',
      last_name: 'Doe',
      email: 'john@example.com',
      phone1: '5551234567',
      property_id: property.id
    }
  }
  
  before do
    property_listing
  end
  
  describe "#call" do
    context "with normal lead creation" do
      before do
        # Disable OpenAI parser for normal lead creation tests
        allow(ENV).to receive(:fetch).with('ENABLE_OPENAI_PARSER', 'false').and_return('false')
      end
      
      it "creates a lead successfully" do
        creator = described_class.new(data: valid_lead_data, token: lead_source.api_token)
        result_lead = creator.call
        
        expect(result_lead.errors).to be_empty
        expect(creator.status).to eq(:ok)
      end
    end
    
    context "with async processing status" do
      let(:mock_parser) { double('Parser') }
      let(:async_result) {
        Leads::Creator::Result.new(
          status: :async_processing,
          lead: {},
          errors: ActiveModel::Errors.new(Lead.new),
          property_code: property.id.to_s,
          parser: 'OpenAI (Async)'
        )
      }
      
      before do
        allow(described_class).to receive(:get_parser).and_return(Leads::Adapters::Cloudmailin)
        allow_any_instance_of(Leads::Adapters::Cloudmailin).to receive(:parse).and_return(async_result)
      end
      
      it "does not create a lead and returns empty lead with error" do
        creator = described_class.new(data: valid_lead_data, token: lead_source.api_token)
        
        expect {
          result_lead = creator.call
          expect(result_lead).not_to be_persisted
          expect(result_lead.errors.full_messages).to include("Lead is being processed asynchronously")
          expect(creator.status).to eq(:async_processing)
        }.not_to change { Lead.count }
      end
    end
    
    context "with invalid token" do
      it "returns error without creating lead" do
        creator = described_class.new(data: valid_lead_data, token: 'invalid_token')
        
        expect {
          result_lead = creator.call
          expect(result_lead).not_to be_persisted
          expect(result_lead.errors.full_messages).to include(/Invalid Access Token/)
        }.not_to change { Lead.count }
      end
    end
    
    context "with missing parser" do
      before do
        allow(described_class).to receive(:get_parser).and_return(nil)
      end
      
      it "returns error without creating lead" do
        creator = described_class.new(data: valid_lead_data, token: lead_source.api_token)
        
        expect {
          result_lead = creator.call
          expect(result_lead).not_to be_persisted
          expect(result_lead.errors.full_messages).to include(/Parser for Lead Source not found/)
        }.not_to change { Lead.count }
      end
    end
  end
  
  describe "status tracking" do
    before do
      # Disable OpenAI parser for normal status tracking tests
      allow(ENV).to receive(:fetch).with('ENABLE_OPENAI_PARSER', 'false').and_return('false')
    end
    
    it "tracks status from parser result" do
      creator = described_class.new(data: valid_lead_data, token: lead_source.api_token)
      result_lead = creator.call
      
      expect(creator.status).to eq(:ok)
    end
    
    context "with async processing" do
      let(:async_result) {
        Leads::Creator::Result.new(
          status: :async_processing,
          lead: {},
          errors: ActiveModel::Errors.new(Lead.new),
          property_code: property.id.to_s,
          parser: 'OpenAI (Async)'
        )
      }
      
      before do
        allow(described_class).to receive(:get_parser).and_return(Leads::Adapters::Cloudmailin)
        allow_any_instance_of(Leads::Adapters::Cloudmailin).to receive(:parse).and_return(async_result)
      end
      
      it "tracks async_processing status" do
        creator = described_class.new(data: valid_lead_data, token: lead_source.api_token)
        creator.call
        
        expect(creator.status).to eq(:async_processing)
      end
    end
  end
end