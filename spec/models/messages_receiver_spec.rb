require 'rails_helper'

RSpec.describe Messages::Receiver do
  include_context "cloudmailin_incoming_message"
  include_context "twilio_incoming_message"


  describe "CloudMailin" do
    let(:receiver) {
      Messages::Receiver.new(data: cmi_message_data, token: cloudmailin_adapter_token)
    }

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

  describe "Twilio" do
    let(:receiver) {
      Messages::Receiver.new(data: twilio_message_data, token: twilio_adapter_token)
    }

    it "is initialized with request params and a token" do
      expect(receiver.source).to eq(twilio_delivery_adapter)
      expect(receiver.parser).to eq(Messages::DeliveryAdapters::TwilioAdapter)
    end

    describe "execute" do
      it "creates a Message and Delivery" do
        sms_message
        message_count = Message.count
        delivery_count = MessageDelivery.count

        new_message = receiver.execute
        expect(new_message.valid?).to eq(true)

        expect(new_message.user).to eq(sms_message_user)
        expect(new_message.messageable).to eq(sms_message_lead)
        expect(new_message.threadid).to eq(sms_message_threadid)

        expect(Message.count).to eq(message_count + 1)
        expect(MessageDelivery.count).to eq(delivery_count + 1)
        expect(Message.for_thread(sms_message_threadid).count).to eq(2)
      end
    end

  end
end
