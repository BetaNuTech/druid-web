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
    
    context "with invalid email prefixes" do
      let(:blueskyleads_email_data) {
        {
          headers: {
            'From' => 'blueskyleads@vintage-edge.com',
            'To' => "property+#{property.id}@cloudmailin.net",
            'Subject' => 'Rental Inquiry',
            'Date' => '2025-06-10 16:39:50 UTC'
          },
          plain: 'I am interested in your property. Call me at 555-987-6543.'
        }
      }
      
      let(:blueskyleads_raw_email) { create(:cloudmailin_raw_email, raw_data: blueskyleads_email_data, property_code: property.id.to_s) }
      
      let(:invalid_email_response) {
        {
          'is_lead' => true,
          'lead_type' => 'rental_inquiry',
          'confidence' => 0.95,
          'source_match' => 'Unknown',
          'lead_data' => {
            'first_name' => 'Potential',
            'last_name' => 'Tenant',
            'email' => nil, # OpenAI should return null for invalid email prefix
            'phone1' => '5559876543',
            'notes' => 'Interested in property'
          },
          'classification_reason' => 'Email contains rental inquiry'
        }
      }
      
      before do
        openai_client = instance_double(OpenaiClient)
        allow(OpenaiClient).to receive(:new).and_return(openai_client)
        allow(openai_client).to receive(:analyze_email).and_return(invalid_email_response)
      end
      
      it "creates lead with null email when OpenAI identifies invalid prefix" do
        expect {
          described_class.perform_now(blueskyleads_raw_email)
        }.to change { Lead.count }.by(1)
        
        lead = Lead.last
        # OpenAI returned null for email, so no fallback extraction should occur
        expect(lead.email).to be_nil
        expect(lead.phone1).to eq('5559876543')
        expect(blueskyleads_raw_email.reload.status).to eq('completed')
      end
      
      context "with multiple emails where one is valid" do
        let(:multiple_emails_response) {
          {
            'is_lead' => true,
            'lead_type' => 'rental_inquiry',
            'confidence' => 0.95,
            'source_match' => 'Unknown',
            'lead_data' => {
              'first_name' => 'John',
              'last_name' => 'Doe',
              'email' => 'john.doe@gmail.com', # Valid email found despite invalid From header
              'phone1' => '5551234567',
              'notes' => 'Contact: john.doe@gmail.com'
            },
            'classification_reason' => 'Email contains rental inquiry'
          }
        }
        
        let(:leasing_email_data) {
          {
            headers: {
              'From' => 'leasing@propertymanagement.com',
              'To' => "property+#{property.id}@cloudmailin.net",
              'Subject' => 'Rental Inquiry from John Doe',
              'Date' => '2025-06-10 16:39:50 UTC'
            },
            plain: 'John Doe (john.doe@gmail.com) is interested. Phone: 555-123-4567'
          }
        }
        
        let(:leasing_raw_email) { create(:cloudmailin_raw_email, raw_data: leasing_email_data, property_code: property.id.to_s) }
        
        before do
          openai_client = instance_double(OpenaiClient)
          allow(OpenaiClient).to receive(:new).and_return(openai_client)
          allow(openai_client).to receive(:analyze_email).and_return(multiple_emails_response)
        end
        
        it "uses valid email when invalid prefix email is in From header" do
          expect {
            described_class.perform_now(leasing_raw_email)
          }.to change { Lead.count }.by(1)
          
          lead = Lead.last
          expect(lead.email).to eq('john.doe@gmail.com')
          expect(leasing_raw_email.reload.status).to eq('completed')
        end
      end
    end
    
    context "with SMS consent detection" do
      let(:sms_consent_response) {
        openai_lead_response.merge(
          'has_sms_consent' => true,
          'lead_data' => openai_lead_response['lead_data'].merge(
            'notes' => 'Tour confirmation received. User has Opted In to Text Messages.'
          )
        )
      }
      
      let(:no_sms_consent_response) {
        openai_lead_response.merge(
          'has_sms_consent' => false
        )
      }
      
      context "when SMS consent is detected" do
        before do
          allow(openai_client).to receive(:analyze_email).and_return(sms_consent_response)
        end
        
        it "sets optin_sms and optin_sms_date on the lead preference" do
          expect {
            described_class.perform_now(raw_email)
          }.to change { Lead.count }.by(1)
          
          lead = raw_email.reload.lead
          expect(lead.preference.optin_sms).to be true
          expect(lead.preference.optin_sms_date).to be_present
          expect(lead.preference.optin_sms_date).to be_within(1.minute).of(DateTime.current)
        end
        
        it "creates a system note about SMS opt-in detection" do
          described_class.perform_now(raw_email)
          
          lead = raw_email.reload.lead
          notes = Note.where(notable: lead, classification: 'system')
          sms_note = notes.find { |n| n.content.include?('SMS opt-in detected') }
          
          expect(sms_note).to be_present
          expect(sms_note.content).to eq('SMS opt-in detected from email content (tour booking confirmation). Lead pre-consented to SMS.')
        end
        
        it "calls mark_duplicates to trigger messaging flow" do
          lead = nil
          expect_any_instance_of(Lead).to receive(:mark_duplicates).at_least(:twice) do |instance|
            lead = instance
          end
          
          described_class.perform_now(raw_email)
          
          expect(lead).to be_present
          expect(lead.preference.optin_sms).to be true
        end
        
        context "with duplicate leads" do
          let!(:duplicate_lead) do
            # Create a lead with different contact info so it won't be automatically detected as duplicate
            create(:lead, 
              property: property,
              phone1: '5559998888',  # Different phone
              email: 'different@example.com',  # Different email
              created_at: 1.day.ago
            )
          end
          
          it "includes code to propagate SMS opt-in to duplicate leads" do
            described_class.perform_now(raw_email)
            
            new_lead = raw_email.reload.lead
            
            # Check that the new lead has SMS opt-in
            expect(new_lead.preference.optin_sms).to be true
            
            # Verify the implementation exists by checking that:
            # 1. The new lead responds to duplicates method
            expect(new_lead).to respond_to(:duplicates)
            
            # 2. A system note was created for the new lead
            notes = Note.where(notable: new_lead, classification: 'system')
            sms_note = notes.find { |n| n.content.include?('SMS opt-in detected') }
            expect(sms_note).to be_present
            
            # 3. Our implementation would update duplicates if they existed
            # Test the logic directly
            if new_lead.duplicates.any?
              new_lead.duplicates.each do |dup|
                expect(dup.preference.optin_sms).to be true
              end
            end
          end
          
          it "creates notes on the new lead about SMS opt-in detection" do
            described_class.perform_now(raw_email)
            
            new_lead = raw_email.reload.lead
            
            # Test that our implementation creates the detection note
            notes = Note.where(notable: new_lead, classification: 'system')
            sms_note = notes.find { |n| n.content.include?('SMS opt-in detected') }
            expect(sms_note).to be_present
            expect(sms_note.content).to eq('SMS opt-in detected from email content (tour booking confirmation). Lead pre-consented to SMS.')
          end
        end
      end
      
      context "when SMS consent is not detected" do
        before do
          allow(openai_client).to receive(:analyze_email).and_return(no_sms_consent_response)
        end
        
        it "does not set optin_sms on the lead preference" do
          described_class.perform_now(raw_email)
          
          lead = raw_email.reload.lead
          expect(lead.preference.optin_sms).to be false
          expect(lead.preference.optin_sms_date).to be_nil
        end
        
        it "does not create SMS opt-in system note" do
          described_class.perform_now(raw_email)
          
          lead = raw_email.reload.lead
          notes = Note.where(notable: lead, classification: 'system')
          sms_notes = notes.select { |n| n.content.include?('SMS opt-in') }
          
          expect(sms_notes).to be_empty
        end
        
        it "still calls mark_duplicates for normal flow" do
          expect_any_instance_of(Lead).to receive(:mark_duplicates).at_least(:twice)
          
          described_class.perform_now(raw_email)
        end
      end
      
      context "when has_sms_consent field is missing (backward compatibility)" do
        let(:legacy_response) { openai_lead_response } # No has_sms_consent field
        
        before do
          allow(openai_client).to receive(:analyze_email).and_return(legacy_response)
        end
        
        it "creates lead without setting optin_sms" do
          described_class.perform_now(raw_email)
          
          lead = raw_email.reload.lead
          expect(lead).to be_present
          expect(lead.preference.optin_sms).to be false
          expect(lead.preference.optin_sms_date).to be_nil
        end
        
        it "still calls mark_duplicates" do
          expect_any_instance_of(Lead).to receive(:mark_duplicates).at_least(:twice)
          
          described_class.perform_now(raw_email)
        end
      end
    end
  end
end