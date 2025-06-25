require 'rails_helper'

RSpec.describe "Leads::Messaging compliance message handling", type: :model do
  include_context "users"
  include_context "messaging"
  include_context "engagement_policy"

  let(:property) { create(:property) }
  let(:lead) { create(:lead, property: property, state: 'open', email: 'test@example.com', phone1: '555-555-5555') }
  let(:sms_opt_in_template) { create(:message_template, name: 'SMS Opt-In Request') }
  let(:sms_opt_in_confirmation_template) { create(:message_template, name: 'SMS Opt-In Confirmation') }
  let(:sms_opt_out_confirmation_template) { create(:message_template, name: 'SMS Opt-Out Confirmation') }

  before do
    # Enable lead automatic reply feature
    allow(Flipflop).to receive(:enabled?).and_return(false)
    allow(Flipflop).to receive(:enabled?).with(:lead_automatic_reply).and_return(true)
    
    # Disable delayed job for testing
    Delayed::Worker.delay_jobs = false
    
    # Enable lead_auto_welcome on property
    property.switch_setting!(:lead_auto_welcome, true)
    
    # Create necessary templates
    sms_opt_in_template
    sms_opt_in_confirmation_template
    sms_opt_out_confirmation_template
    
    # Create necessary lead actions and reasons
    create(:lead_action, name: 'Lead Email/SMS Opt-In')
    create(:lead_action, name: 'Lead Email/SMS Opt-Out')
    create(:reason, name: 'Follow-Up')
  end
  
  after do
    # Re-enable delayed job
    Delayed::Worker.delay_jobs = true
  end

  describe "#send_compliance_message" do
    context "when sending SMS opt-in request" do
      it "creates a note with the correct template name" do
        initial_count = Note.where(notable: lead).count
        
        lead.send_compliance_message(
          message_type: MessageType.sms,
          disposition: :request,
          assent: true
        )
        
        notes = Note.where(notable: lead).order(:created_at)
        expect(notes.count - initial_count).to be >= 1
        
        # Find the compliance message note specifically for opt-in request
        compliance_note = notes.find { |n| n.content == "SENT: SMS Opt-In Request" }
        expect(compliance_note).to be_present
        expect(compliance_note.content).to eq("SENT: SMS Opt-In Request")
        expect(compliance_note.content).not_to include("None")
        expect(compliance_note.classification).to eq('system')
      end
    end

    context "when sending SMS opt-in confirmation" do
      it "creates a note with the correct template name" do
        initial_count = Note.where(notable: lead).count
        
        lead.send_compliance_message(
          message_type: MessageType.sms,
          disposition: :confirmation,
          assent: true
        )
        
        notes = Note.where(notable: lead).order(:created_at)
        compliance_note = notes.find { |n| n.content == "SENT: SMS Opt-In Confirmation" }
        expect(compliance_note).to be_present
        expect(compliance_note.content).to eq("SENT: SMS Opt-In Confirmation")
        expect(compliance_note.content).not_to include("None")
      end
    end

    context "when sending SMS opt-out confirmation" do
      it "creates a note with the correct template name" do
        initial_count = Note.where(notable: lead).count
        
        lead.send_compliance_message(
          message_type: MessageType.sms,
          disposition: :confirmation,
          assent: false
        )
        
        notes = Note.where(notable: lead).order(:created_at)
        compliance_note = notes.find { |n| n.content == "SENT: SMS Opt-Out Confirmation" }
        expect(compliance_note).to be_present
        expect(compliance_note.content).to eq("SENT: SMS Opt-Out Confirmation")
        expect(compliance_note.content).not_to include("None")
      end
    end

    context "when template is missing" do
      before { MessageTemplate.destroy_all }
      
      it "creates a note with error message" do
        expect {
          lead.send_compliance_message(
            message_type: MessageType.sms,
            disposition: :request,
            assent: true
          )
        }.to change { Note.where(notable: lead).count }.by(1)
        
        note = Note.where(notable: lead).last
        expect(note.content).to start_with("NOT SENT:")
        expect(note.content).to include("Message template 'SMS Opt-In Request' not found")
      end
    end

    context "when no SMS destination is available" do
      let(:lead) { create(:lead, property: property, state: 'open', phone1: nil, phone2: nil) }
      
      it "does not create a note and returns early" do
        expect {
          lead.send_compliance_message(
            message_type: MessageType.sms,
            disposition: :request,
            assent: true
          )
        }.not_to change { Note.where(notable: lead).count }
      end
    end

    context "when sending email compliance message" do
      it "handles nil template name gracefully" do
        # Email templates aren't defined in the constants
        expect {
          lead.send_compliance_message(
            message_type: MessageType.email,
            disposition: :request,
            assent: true
          )
        }.to change { Note.where(notable: lead).count }.by(1)
        
        note = Note.where(notable: lead).last
        expect(note.content).to eq("NOT SENT: No email template configured for this action")
        expect(note.content).not_to include("None")
      end
    end
  end

  describe "#send_new_lead_messaging" do
    context "when lead is freshly created" do
      it "sends SMS opt-in request with proper note" do
        # Skip the automatic reply 
        allow(lead).to receive(:lead_automatic_reply).and_return(true)
        # Mock that we haven't sent compliance messages before
        allow(lead).to receive(:any_sms_compliance_messages_for_recipient?).and_return(false)
        # Ensure messages can be sent 
        allow(lead).to receive(:open?).and_return(true)
        allow(lead).to receive(:messages).and_return(double(outgoing: double(sms: double(for_compliance: double(any?: false)))))
        
        initial_count = Note.where(notable: lead).count
        
        lead.send_new_lead_messaging
        
        notes = Note.where(notable: lead).order(:created_at)
        compliance_note = notes.find { |n| n.content == "SENT: SMS Opt-In Request" }
        expect(compliance_note).to be_present
        expect(compliance_note.content).to eq("SENT: SMS Opt-In Request")
      end
    end
  end
end