# == Schema Information
#
# Table name: messages
#
#  id                  :uuid             not null, primary key
#  messageable_id      :uuid
#  messageable_type    :string
#  user_id             :uuid             not null
#  state               :string           default("draft"), not null
#  senderid            :string           not null
#  recipientid         :string           not null
#  message_template_id :uuid
#  subject             :string           not null
#  body                :text             not null
#  delivered_at        :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

require 'rails_helper'

RSpec.describe Message, type: :model do
  describe "initialization" do
    it "can be initialized" do
      message = build(:message)
      message.save
      assert message.valid?
    end
  end

  describe "associations" do
    let(:message) {  create(:message) }

    it "belongs to a user" do
      expect(message.user).to be_a(User)
    end

    it "belongs to a 'messageable' (polymorphic)" do
      lead = create(:lead)
      message.messageable = lead
      message.save
      message.reload
      expect(message.messageable).to be_a(Lead)
    end

    it "sometimes belongs to a message_template" do
      expect(message.message_template).to be_a(MessageTemplate)
      assert message.valid?
      message.message_template = nil
      assert message.valid?
    end
  end

  describe "validations" do
    let(:message) {  create(:message) }

    it "always has a state" do
      assert message.valid?
      message.state = nil
      refute message.valid?
    end
    it "always has a recipientid" do
      assert message.valid?
      message.recipientid = nil
      refute message.valid?
    end
    it "always has a senderid" do
      assert message.valid?
      message.senderid = nil
      refute message.valid?
    end
    it "always has a subject" do
      assert message.valid?
      message.subject = nil
      refute message.valid?
    end
    it "always has a body" do
      assert message.valid?
      message.body = nil
      refute message.valid?
    end
  end

  describe "state machine" do
    let(:message) {  create(:message) }
    it "has possible states" do
      expect(Message.state_names.sort).to eq(['draft', 'sent', 'failed' ].sort)
    end
    it "is initialized to the 'draft' state" do
      expect(message.state).to eq('draft')
    end
    it "can transition from draft to sent with a 'deliver' event" do
      expect(message.state).to eq('draft')
      message.deliver!
      expect(message.state).to eq('sent')
    end
    it "can transition from sent to failed with the 'fail' event" do
      expect(message.state).to eq('draft')
      message.deliver!
      expect(message.state).to eq('sent')
      message.fail!
      expect(message.state).to eq('failed')
    end
  end
end
