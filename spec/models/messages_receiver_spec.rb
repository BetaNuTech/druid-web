require 'rails_helper'

RSpec.describe Messages::Receiver do
  include_context "cloudmailin_incoming_message"
  let(:receiver) {
    message
    Messages::Receiver.new(data: cmi_message_data, token: cloudmailin_adapter_token)
  }

  describe "CloudMailin" do
    it "is initialized with request params and a token" do
      expect(receiver.source).to eq(cloudmailin_delivery_adapter)
      expect(receiver.parser).to eq(Messages::DeliveryAdapters::CloudMailin)
    end

    describe "execute" do
      it "creates a Message and Delivery" do
        message
        message_count = Message.count
        delivery_count = MessageDelivery.count

        new_message = receiver.execute
        expect(new_message.valid?).to eq(true)

        expect(new_message.user).to eq(message_user)
        expect(new_message.messageable).to eq(message_lead)
        expect(new_message.threadid).to eq(message_threadid)

        expect(Message.count).to eq(message_count + 1)
        expect(MessageDelivery.count).to eq(delivery_count + 1)
        expect(Message.for_thread(message_threadid).count).to eq(2)
      end
    end

  end

end
