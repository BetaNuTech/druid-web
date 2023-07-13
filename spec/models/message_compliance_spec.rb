require 'rails_helper'

RSpec.describe "Lead Message Preference Compliance" do
  include_context "engagement_policy"
  include_context "message_templates"
  include_context "messaging"
  include_context "users"

  let(:lead) {
    lead = create(:lead, state: 'open', phone1: '9555555559', phone1_type: 'Cell', user: agent, property: agent.property)
    lead
  }

  describe "for SMS communications" do
    include_context "twilio_incoming_message"

      let(:token) { twilio_adapter_token }
      let(:claimed_lead) {
        lead.preference.optin_sms = false
        lead.preference.optin_sms_date = nil
        lead.preference.save!
        lead.trigger_event(event_name: 'claim', user: agent)
        lead.reload
        lead
      }
      let(:acceptance_sms_payload) {
        request_message = claimed_lead.messages.last
        {
          'To' => request_message.senderid,
          'From' => request_message.recipientid,
          'Subject' => 'None',
          'Body' => 'Yes'
        }
      }
      let(:refusal_sms_payload) {
        request_message = claimed_lead.messages.last
        {
          'To' => request_message.senderid,
          'From' => request_message.recipientid,
          'Subject' => 'None',
          'Body' => 'STOP'
        }
      }

    before do
      lead.property.switch_setting!(:lead_auto_welcome, true)
      seed_engagement_policy
    end

    describe "when the lead has not opted into sms communication" do
      before do
        lead.preference.optin_sms = false
        lead.preference.optin_sms_date = nil
        lead.save!
      end

      it "should not allow an sms message to be sent" do
        message = Message.new_message(
          from: agent,
          to: lead,
          message_type: MessageType.sms,
          body: 'This is a test',
          subject: 'None'
        )

        message.save!
        message.deliver!
        refute(message.deliveries.last.success?)
      end

    ### This is done on create now
      #describe "when claiming a lead" do
        #it "sends an sms opt-in request" do
          #expect(lead.messages.for_compliance.count).to eq(0)
          #lead.trigger_event(event_name: 'claim', user: agent)
          #lead.reload
          #expect(lead.messages.for_compliance.count).to eq(1)
        #end
      #end

      describe "when receiving a reply" do

        before do
          token
        end

        describe "if the message includes the word 'YES'" do
          it "opts in the lead for sms communication" do
            refute(lead.optin_sms?)
            data = acceptance_sms_payload
            adapter = Messages::Receiver.new(data: data, token: token)
            message = adapter.call
            lead.reload
            assert(lead.optin_sms?)
          end
        end

        describe "if the message includes the word 'STOP'" do
          it "opts out the lead for sms communication" do
            lead.optin_sms!
            lead.reload
            assert(lead.optin_sms?)
            data = refusal_sms_payload
            adapter = Messages::Receiver.new(data: data, token: token)
            message = adapter.call
            lead.reload
            refute(lead.optin_sms?)
          end
        end
      end
    end

    describe "when the lead has opted into sms communication" do

      before do
        ENV[MessageType::SMS_MESSAGING_DISABLED_FLAG] = 'false'
        lead.preference.optin_sms = true
        lead.preference.optin_sms_date = DateTime.current
        lead.preference.save!
        lead.reload
      end

      describe "when a system flag disables SMS messaging" do
        it "should not send the message" do
          ENV[MessageType::SMS_MESSAGING_DISABLED_FLAG] = 'true'
          message = Message.new_message(
            from: agent,
            to: lead,
            message_type: MessageType.sms,
            body: 'This is a test',
            subject: 'None'
          )

          message.save!
          message.deliver!
          refute(message.deliveries.last.success?)
          ENV[MessageType::SMS_MESSAGING_DISABLED_FLAG] = 'false'
        end
      end

      it "should allow sms messages to be sent" do
        message = Message.new_message(
          from: agent,
          to: lead,
          message_type: MessageType.sms,
          body: 'This is a test',
          subject: 'None'
        )

        message.save!
        message.deliver!
        assert(message.deliveries.last.success?)
      end

      describe "when receiving a reply" do
        describe "if the message includes the word 'YES'" do
          it "opts in the lead for sms communication" do
            assert(lead.optin_sms?)
            data = acceptance_sms_payload
            adapter = Messages::Receiver.new(data: data, token: token)
            message = adapter.call
            lead.reload
            assert(lead.optin_sms?)
          end
        end

        describe "if the message includes the word 'STOP'" do
          it "opts out the lead for sms communication" do
            assert(lead.optin_sms?)
            data = refusal_sms_payload
            adapter = Messages::Receiver.new(data: data, token: token)
            message = adapter.call
            lead.reload
            refute(lead.optin_sms?)
          end
        end
      end
    end

  end

end
