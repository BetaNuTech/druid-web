require 'rails_helper'

RSpec.describe MessageDelivery, type: :model do

  describe "associations" do
    let(:message){ create(:message)}
    let(:message_type) { message.message_type }

    it "has a message" do
      md = MessageDelivery.new(
        message: message,
        message_type: message_type
      )

      assert md.message.is_a?(Message)
    end

    it "has a message_type" do
      md = MessageDelivery.new(
        message: message,
        message_type: message_type
      )
      assert md.message_type.is_a?(MessageType)
    end
  end

  describe "Validations"

  describe "Message Helpers" do
    let(:message){create(:message)}
    let(:message2){create(:message)}

    it "automatically sets the attempt number" do
      md1 = MessageDelivery.create!(message: message, message_type: message.message_type)
      expect(md1.attempt).to eq(1)
      md2 = MessageDelivery.create(message: message, message_type: message.message_type)
      expect(md2.attempt).to eq(2)
    end

    it "returns the latest delivery attempt for a message" do
      md1 = MessageDelivery.create(message: message, message_type: message.message_type)
      md2 = MessageDelivery.create(message: message2, message_type: message2.message_type)
      expect(MessageDelivery.previous(message)).to eq(md1)
      md3 = MessageDelivery.create(message: message, message_type: message.message_type, attempt: 2)
      expect(MessageDelivery.previous(message)).to eq(md3)
    end

    it "returns whether it has been delivered" do
      md1 = MessageDelivery.create(message: message, message_type: message.message_type)
      refute md1.delivered?
      md1.delivered_at = DateTime.now
      md1.save
      assert md1.delivered?
    end
  end

end
