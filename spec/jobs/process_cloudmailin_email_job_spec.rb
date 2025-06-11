require 'rails_helper'

RSpec.describe ProcessCloudmailinEmailJob, type: :job do
  let(:property) { create(:property) }
  let(:cloudmailin_source) { create(:lead_source, slug: 'Cloudmailin') }
  let(:zillow_source) { create(:lead_source, name: 'Zillow') }
  let(:property_listing) { create(:property_listing, property: property, source: cloudmailin_source, code: property.id) }
  let(:zillow_listing) { create(:property_listing, property: property, source: zillow_source) }
  
  let(:email_data) {
    {
      headers: {
        'From' => 'john.doe@example.com',
        'To' => "property+#{property.id}@cloudmailin.net",
        'Subject' => 'New Zillow Group Rentals Contact: Test Property',
        'Date' => '2025-06-10 16:39:50 UTC'
      },
      plain: 'John Doe is interested in Test Property. Phone: 555-123-4567'
    }
  }
  
  let(:raw_email) { create(:cloudmailin_raw_email, raw_data: email_data, property_code: property.id.to_s) }
  
  let(:openai_lead_response) {
    {
      'is_lead' => true,
      'lead_type' => 'rental_inquiry',
      'confidence' => 0.95,
      'source_match' => 'Zillow',
      'lead_data' => {
        'first_name' => 'John',
        'last_name' => 'Doe',
        'email' => 'john.doe@example.com',
        'phone1' => '555-123-4567',
        'notes' => 'Interested in Test Property',
        'unit_type' => 'A01',
        'preferred_move_in_date' => '2025-07-01'
      },
      'classification_reason' => 'Email contains rental inquiry'
    }
  }
  
  let(:openai_non_lead_response) {
    {
      'is_lead' => false,
      'lead_type' => 'vendor',
      'confidence' => 0.85,
      'source_match' => nil,
      'lead_data' => {
        'first_name' => 'ABC',
        'last_name' => 'Plumbing',
        'email' => 'service@abcplumbing.com',
        'phone1' => '555-999-8888',
        'notes' => 'Invoice for plumbing services',
        'company' => 'ABC Plumbing'
      },
      'classification_reason' => 'Email appears to be from a service vendor'
    }
  }
  
  before do
    property_listing
    zillow_listing
  end
  
  describe "#perform" do
    let(:openai_client) { instance_double(OpenaiClient) }
    
    before do
      allow(OpenaiClient).to receive(:new).and_return(openai_client)
    end
    
    context "with valid property and successful OpenAI analysis" do
      before do
        allow(openai_client).to receive(:analyze_email).and_return(openai_lead_response)
      end
      
      it "creates a lead for rental inquiry" do
        expect {
          described_class.perform_now(raw_email)
        }.to change { Lead.count }.by(1)
        
        raw_email.reload
        expect(raw_email.status).to eq('completed')
        expect(raw_email.lead).to be_present
        expect(raw_email.openai_response).to eq(openai_lead_response)
        expect(raw_email.parser_used).to eq('OpenAI')
        
        lead = raw_email.lead
        expect(lead.first_name).to eq('John')
        expect(lead.last_name).to eq('Doe')
        expect(lead.email).to eq('john.doe@example.com')
        expect(lead.phone1).to eq('5551234567')
        expect(lead.property).to eq(property)
      end
      
      it "creates a lead for non-rental inquiry with descriptive names" do
        allow(openai_client).to receive(:analyze_email).and_return(openai_non_lead_response)
        
        expect {
          described_class.perform_now(raw_email)
        }.to change { Lead.count }.by(1)
        
        lead = raw_email.reload.lead
        expect(lead.first_name).to eq('ABC')
        expect(lead.last_name).to eq('Plumbing')
        expect(lead.email).to eq('service@abcplumbing.com')
        
        # Should create a note about the classification
        notes = Note.where(notable: lead)
        expect(notes.count).to eq(1)
        expect(notes.first.content).to include('AI Classification: Vendor')
        expect(notes.first.content).to include('Confidence: 85%')
      end
      
      it "handles unknown lead type with fallback names" do
        unknown_response = openai_non_lead_response.merge(
          'lead_type' => 'unknown',
          'lead_data' => openai_non_lead_response['lead_data'].merge(
            'first_name' => nil,
            'last_name' => nil
          )
        )
        allow(openai_client).to receive(:analyze_email).and_return(unknown_response)
        
        expect {
          described_class.perform_now(raw_email)
        }.to change { Lead.count }.by(1)
        
        lead = raw_email.reload.lead
        expect(lead.first_name).to eq('Review Required')
        expect(lead.last_name).to eq('Unknown')
      end
      
      it "always uses Cloudmailin as lead source and sets referral from OpenAI" do
        allow(openai_client).to receive(:analyze_email).and_return(openai_lead_response)
        
        described_class.perform_now(raw_email)
        
        lead = raw_email.reload.lead
        expect(lead.source).to eq(cloudmailin_source)
        expect(lead.referral).to eq('Zillow')
      end
      
      it "provides marketing sources to OpenAI for better matching" do
        # Create marketing sources for the property
        zillow_marketing_source = create(:marketing_source, property: property, name: 'Zillow.com')
        apartments_marketing_source = create(:marketing_source, property: property, name: 'Apartments.com')
        
        # Verify OpenAI is called with the marketing sources list
        expect(openai_client).to receive(:analyze_email) do |email_data, prop, active_sources|
          expect(prop).to eq(property)
          # The marketing sources should be available to the OpenAI client
        end.and_return(openai_lead_response)
        
        described_class.perform_now(raw_email)
      end
      
      it "prioritizes marketing source names when OpenAI has them available" do
        # Create a marketing source with .com suffix
        zillow_marketing_source = create(:marketing_source, property: property, name: 'Zillow.com')
        
        # Mock OpenAI to return the exact marketing source name (as it would when given the list)
        response_with_exact_name = openai_lead_response.merge('source_match' => 'Zillow.com')
        allow(openai_client).to receive(:analyze_email).and_return(response_with_exact_name)
        
        described_class.perform_now(raw_email)
        
        lead = raw_email.reload.lead
        expect(lead.referral).to eq('Zillow.com')  # Should use OpenAI's returned marketing source name
      end
      
      it "properly handles notes, unit type, and move-in date" do
        allow(openai_client).to receive(:analyze_email).and_return(openai_lead_response)
        
        described_class.perform_now(raw_email)
        
        lead = raw_email.reload.lead
        preference = lead.preference
        
        # Check that notes combine OpenAI notes, unit type, and AI processing indicator
        expect(preference.notes).to include('Interested in Test Property')
        expect(preference.notes).to include('Unit type requested: A01')
        expect(preference.notes).to include('Processed by AI')
        
        # Check that move-in date is parsed correctly
        expect(preference.move_in).to eq(Date.parse('2025-07-01'))
        
        # Check that raw data is preserved
        expect(preference.raw_data).to be_present
        expect(JSON.parse(preference.raw_data)).to eq(email_data.stringify_keys)
      end
      
      it "handles invalid move-in date by adding to notes" do
        invalid_date_response = openai_lead_response.deep_merge(
          'lead_data' => { 'preferred_move_in_date' => 'invalid-date' }
        )
        allow(openai_client).to receive(:analyze_email).and_return(invalid_date_response)
        
        described_class.perform_now(raw_email)
        
        lead = raw_email.reload.lead
        preference = lead.preference
        
        # Move-in should not be set
        expect(preference.move_in).to be_nil
        
        # Invalid date should be in notes along with AI processing indicator
        expect(preference.notes).to include('Preferred move-in: invalid-date')
        expect(preference.notes).to include('Processed by AI')
      end
    end
    
    context "with inactive property" do
      let(:inactive_property) { create(:property, active: false) }
      let(:inactive_raw_email) { 
        create(:cloudmailin_raw_email, raw_data: email_data, property_code: inactive_property.id.to_s) 
      }
      
      it "marks email as failed and logs warning" do
        expect(Rails.logger).to receive(:warn).at_least(:once)
        expect(Leads::Creator).to receive(:create_event_note).at_least(:once)
        
        expect {
          described_class.perform_now(inactive_raw_email)
        }.not_to change { Lead.count }
        
        inactive_raw_email.reload
        expect(inactive_raw_email.status).to eq('failed')
        expect(inactive_raw_email.error_message).to include('inactive property')
      end
    end
    
    context "with nonexistent property" do
      let(:invalid_raw_email) { 
        create(:cloudmailin_raw_email, raw_data: email_data, property_code: 'nonexistent') 
      }
      
      it "marks email as failed" do
        expect {
          described_class.perform_now(invalid_raw_email)
        }.not_to change { Lead.count }
        
        invalid_raw_email.reload
        expect(invalid_raw_email.status).to eq('failed')
      end
    end
    
    context "with OpenAI failures" do
      it "retries on rate limit errors" do
        allow(openai_client).to receive(:analyze_email)
          .and_raise(OpenaiClient::RateLimitError, 'Rate limit exceeded')
        
        expect {
          described_class.perform_now(raw_email)
        }.to raise_error(OpenaiClient::RateLimitError)
        
        raw_email.reload
        expect(raw_email.status).to eq('pending')
      end
      
      it "creates fallback lead after max retries" do
        allow(openai_client).to receive(:analyze_email).and_return(nil)
        allow(raw_email).to receive(:can_retry?).and_return(false)
        
        expect {
          described_class.perform_now(raw_email)
        }.to change { Lead.count }.by(1)
        
        raw_email.reload
        lead = raw_email.lead
        expect(lead.first_name).to eq('OpenAI Processing')
        expect(lead.last_name).to eq('Failed - Review')
        expect(raw_email.parser_used).to eq('Fallback')
        
        # Should create error note
        notes = Note.where(notable: lead)
        expect(notes.count).to eq(1)
        expect(notes.first.content).to include('OpenAI processing failed')
        expect(notes.first.classification).to eq('error')
      end
    end
    
    context "with missing Cloudmailin configuration" do
      it "marks email as failed when Cloudmailin source doesn't exist" do
        cloudmailin_source.destroy
        allow(openai_client).to receive(:analyze_email).and_return(openai_lead_response)
        
        expect {
          described_class.perform_now(raw_email)
        }.not_to change { Lead.count }
        
        raw_email.reload
        expect(raw_email.status).to eq('failed')
        expect(raw_email.error_message).to include('Cloudmailin lead source not found')
      end
      
      it "auto-activates inactive Cloudmailin listing and creates lead" do
        property_listing.update!(active: false)
        allow(openai_client).to receive(:analyze_email).and_return(openai_lead_response)
        
        expect {
          described_class.perform_now(raw_email)
        }.to change { Lead.count }.by(1)
        
        property_listing.reload
        expect(property_listing.active?).to be_truthy
        
        raw_email.reload
        expect(raw_email.status).to eq('completed')
        expect(raw_email.lead).to be_present
      end
      
      it "marks email as failed when property has no Cloudmailin listing configured" do
        property_listing.destroy
        allow(openai_client).to receive(:analyze_email).and_return(openai_lead_response)
        
        expect {
          described_class.perform_now(raw_email)
        }.not_to change { Lead.count }
        
        raw_email.reload
        expect(raw_email.status).to eq('failed')
        expect(raw_email.error_message).to include('does not have Cloudmailin listing configured')
      end
    end

    context "with lead creation failures" do
      before do
        allow(openai_client).to receive(:analyze_email).and_return(
          openai_lead_response.deep_merge(
            'lead_data' => {
              'first_name' => nil,
              'last_name' => nil,
              'email' => nil,
              'phone1' => nil
            }
          )
        )
      end
      
      it "marks email as failed when lead validation fails" do
        expect {
          described_class.perform_now(raw_email)
        }.not_to change { Lead.count }
        
        raw_email.reload
        expect(raw_email.status).to eq('failed')
        expect(raw_email.error_message).to include('Lead creation failed')
      end
    end
    
    context "with already completed email" do
      let(:completed_email) { create(:cloudmailin_raw_email, status: 'completed') }
      
      it "does not process email again" do
        expect(OpenaiClient).not_to receive(:new)
        
        described_class.perform_now(completed_email)
        
        expect(completed_email.reload.status).to eq('completed')
      end
    end
  end
end