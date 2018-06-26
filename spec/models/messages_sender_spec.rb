require 'rails_helper'

RSpec.describe Messages::Sender do
  describe "Initialization" do
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
end
