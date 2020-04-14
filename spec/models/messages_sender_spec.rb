require 'rails_helper'

RSpec.describe Messages::Sender do
  describe "Initialization" do
    before :each  do
      ENV[MessageDelivery::WHITELIST_FLAG] = 'false'
    end

    let(:message_type) { create(:email_message_type)}
    let(:message) { create(:message, message_type: message_type)}
    let(:delivery) { MessageDelivery.create!(message: message, message_type: message.message_type) }
    let(:message_delivery_adapter_ar) {
      MessageDeliveryAdapter.create!(
        message_type: message_type,
        slug: 'Actionmailer',
        name: 'ActionMailer',
        active: true
      )
    }
    let(:message_delivery_adapter_ar2) {
      MessageDeliveryAdapter.create(
        message_type: message_type,
        slug: 'ActionMailer2',
        name: 'ActionMailer2',
        active: false
      )
    }
    let(:message_delivery_adapter_ar3) {
      MessageDeliveryAdapter.create!(
        message_type: message_type,
        slug: 'Foo',
        name: 'Foo',
        active: true
      )
    }

    it "sets the delivery attribute" do
      message_delivery_adapter_ar
      sender = Messages::Sender.new(delivery)
      expect(sender.delivery).to eq(delivery)
    end

    it "find an appropriate delivery adapter" do
      message_delivery_adapter_ar
      message_delivery_adapter_ar2
      message_delivery_adapter_ar3
      sender = Messages::Sender.new(delivery)
      assert sender.adapter.is_a?(Messages::DeliveryAdapters::Actionmailer)
    end

    it "performs delivery of a message with the correct adapter" do
      message_delivery_adapter_ar
      sender = Messages::Sender.new(delivery)
      refute delivery.delivered?
      expect(sender.adapter).to receive(:deliver)
      sender.deliver
      delivery.reload
      expect(delivery.status).to eq(MessageDelivery::SUCCESS)
      assert delivery.delivered?
    end
  end

  describe "delivery" do
    describe "whitelisting" do
      let(:email_delivery_adapter) { create(:email_delivery_adapter)}
      let(:sms_delivery_adapter) { create(:sms_delivery_adapter)}

      let(:whitelist_user) {
        create(:user, profile: build(:user_profile, {cell_phone: whitelist_number1, office_phone: whitelist_number2, fax: whitelist_number3}))
      }
      let(:sender_user) { create(:user) }

      let(:whitelist_number1) { '5555555555' }
      let(:whitelist_number2) { '5555555556' }
      let(:whitelist_number3) { '5555555556' }
      let(:whitelist_email1) { 'recipient@example.com' }
      let(:other_number1) { '5554445555' }
      let(:other_number2) { '5554445556' }
      let(:other_email1) { 'me@example.com' }
      let(:message_body) { 'Message body text' }
      let(:message_subject) { 'Message subject text' }
      let(:sender_number) { '5553335555' }
      let(:sender_email) { 'sender@example.com' }

      let(:whitelisted_email_message1) {
        Message.create!(
          message_type: MessageType.email,
          user: sender_user,
          recipientid: whitelist_email1,
          senderid: sender_email,
          subject: message_subject,
          body: message_body
        )
      }

      let(:whitelisted_sms_message) {
        Message.create!(
          message_type: MessageType.sms,
          user: sender_user,
          recipientid: whitelist_number1,
          senderid: sender_number,
          subject: message_subject,
          body: message_body
        )
      }

      let(:other_email_message) {
        Message.create!(
          message_type: MessageType.email,
          user: sender_user,
          recipientid: other_email1,
          senderid: sender_email,
          subject: message_subject,
          body: message_body
        )
      }

      let(:other_sms_message) {
        Message.create!(
          message_type: MessageType.sms,
          user: sender_user,
          recipientid: other_number1,
          senderid: sender_number,
          subject: message_subject,
          body: message_body
        )
      }

      before :each do
        email_delivery_adapter
        sms_delivery_adapter
        whitelist_user
      end

      describe "with whitelist enabled" do
        before :each do
          ENV[MessageDelivery::WHITELIST_FLAG] = 'true'
        end

        it "should send an email to a recipient with a whitelisted email address" do
          whitelisted_email_message1.deliver!
          assert(whitelisted_email_message1.sent?)
        end

        it "should send an sms message to a recipient with a whitelisted phone number" do
          whitelisted_sms_message.deliver!
          whitelisted_sms_message.reload
          assert(whitelisted_sms_message.sent?)
        end

        it "should fail to send an email to a recipient with an unwhitelisted email address" do
          other_email_message.deliver!
          other_email_message.reload
          refute(other_email_message.deliveries.successful.exists?)
          assert(other_email_message.deliveries.failed.exists?)
          other_email_message.perform_delivery # only necessary when running without background job
          refute(other_email_message.sent?)
        end

        it "should fail to send an sms message to a recipient with an unwhitelisted phone number" do
          other_sms_message.deliver!
          other_sms_message.reload
          refute(other_sms_message.deliveries.successful.exists?)
          assert(other_sms_message.deliveries.failed.exists?)
          other_sms_message.perform_delivery # only necessary when running without background job
          refute(other_sms_message.sent?)
        end

      end

      describe "with whitelist disabled" do
        before :each do
          ENV[MessageDelivery::WHITELIST_FLAG] = 'false'
        end

        it "should send an email to a recipient with a whitelisted email address" do
          whitelisted_email_message1.deliver!
          whitelisted_email_message1.reload
          assert(whitelisted_email_message1.sent?)
        end

        it "should send an sms message to a recipient with a whitelisted phone number" do
          whitelisted_sms_message.deliver!
          whitelisted_sms_message.reload
          assert(whitelisted_sms_message.sent?)
        end

        it "should send an email to a recipient with an unwhitelisted email address" do
          other_email_message.deliver!
          other_email_message.reload
          assert(other_email_message.sent?)
        end

        it "should send an sms message to a recipient with an unwhitelisted phone number" do
          other_sms_message.deliver!
          other_sms_message.reload
          assert(other_sms_message.sent?)
        end

      end

    end
  end
end
