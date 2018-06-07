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
#  message_type_id     :uuid
#  threadid            :string
#  read_at             :datetime
#  read_by_user_id     :uuid
#

require 'rails_helper'

RSpec.describe Message, type: :model do
  let(:message_type) { MessageType.email || create(:email_message_type) }
  let(:adapter) { create(:email_delivery_adapter, message_type: message_type)}

  before :each do
    adapter
  end

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
      message.messageable = nil
      assert message.recipientid.nil?
      refute message.valid?
      expect( message.errors.to_a).to eq(["Recipientid can't be blank"])
    end
    it "always has a senderid" do
      begin
        Message.skip_callback(:validation, :before, :set_meta)
        assert message.valid?
        message.senderid = nil
        message.validate
        assert message.senderid.nil?
        refute message.valid?
        expect( message.errors.to_a).to eq(["Senderid can't be blank"])
      ensure
        Message.set_callback(:validation, :before, :set_meta)
      end
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

  describe "auto-fill from template" do
    let(:message) { create(:message)}

    it "should report whether filling the message data is without error" do
      assert message.fill
      mt = message.message_template
      mt.body = "{{foo"
      mt.save!
      message.reload
      refute message.fill
    end

    it "should fill the message subject" do
      assert message.fill
      expect(message.subject).to match(message.messageable.name)
    end

    it "should fill the message body" do
      lead = message.messageable
      lead.property = create(:property)
      lead.save!
      message.reload
      assert message.fill
      expect(message.body).to match(message.messageable.property.name)
    end
  end

  describe "using the Message.new_message helper" do
    let(:lead) { create(:lead, user: user)}
    let(:user) { create(:user)}
    let(:message_type) { create(:email_message_type)}
    let(:message_template) { create(:message_template, message_type: message_type)}

    it "assigns a user" do
      message = Message.new_message(from: user, to: lead, message_type: message_type)
      expect(message.user).to eq(user)
    end

    it "assigns the messageable" do
      message = Message.new_message(from: user, to: lead, message_type: message_type)
      expect(message.messageable).to eq(lead)
    end

    it "assigns the message_type" do
      message = Message.new_message(from: user, to: lead, message_type: message_type)
      expect(message.message_type).to eq(message_type)
    end

    it "optionally assigns the message_template if provided" do
      message = Message.new_message(from: user, to: lead, message_type: message_type)
      expect(message.message_template).to be_nil
      message = Message.new_message(from: user, to: lead, message_type: message_type, message_template: message_template)
      expect(message.message_template).to eq(message_template)
    end

    it "optionally assigns the threadid" do
      threadid = SecureRandom.uuid
      message = Message.new_message(from: user, to: lead, message_type: message_type, threadid: threadid)
      expect(message.threadid).to eq(threadid)
    end

    it "fills the message using the message_template if provided" do
      message = Message.new_message(from: user, to: lead, message_type: message_type, message_template: message_template)
      assert message.valid?
      expect(message.subject).to match(lead.name)
      expect(message.body).to match(lead.user.name)
    end



    it "assigns meta information" do
      message = Message.new_message(from: user, to: lead, message_type: message_type)
      expect(message.recipientid).to eq(lead.email)
      expect(message.senderid).to_not be_nil
      expect(message.threadid).to_not be_nil
    end
  end

  describe "callbacks" do
    let(:message) { create(:message)}
    let(:phone) { "555-555-5555" }
    let(:email) { "lead@example.com"}
    let(:lead) { create(:lead, phone1: phone, phone1_type: 'Cell', email: email )}
    let(:sms_message_type) { create(:sms_message_type)}
    let(:email_message_type) { create(:email_message_type)}
    let(:sms_message) { create(:message, { messageable: lead, message_type: sms_message_type } )}
    let(:new_sms_message) { build(:message, { messageable: lead, message_type: sms_message_type } )}

    #it "sets senderid on create" do
      #message
      #expect(sms_message.recipientid).to eq(lead.phone1)
    #end

    #it "sets senderid on update" do
      #sms_message
      #sms_message.senderid = nil
      #sms_message.save
      #expect(sms_message).to_not be_nil
    #end

    #it "sets recipientid on create" do
      #new_sms_message.recipientid = nil
      #new_sms_message.save
      #expect(new_sms_message.recipientid).to_not be_nil
    #end

    it "sets thread id on create" do
      assert new_sms_message.threadid.nil?
      new_sms_message.save
      expect(new_sms_message.threadid).to_not be_nil
    end
  end

  describe "state machine" do
    let(:message) { create(:message, message_type: message_type)}
    describe "delivery" do
      it "sends the message when the message recieves the 'deliver' event" do
        adapter
        assert MessageDelivery.count == 0
        expect(message.delivered_at).to be_nil
        message.deliver!
        assert MessageDelivery.count == 1
        expect(message.delivered_at).to_not be_nil
        expect(message.state).to eq('sent')
        message.reload
        expect(message.deliveries.count).to eq(1)
        delivery = message.deliveries.last
        expect(delivery.attempt).to eq(1)
        expect(MessageDelivery.previous_attempt_number(message)).to eq(1)
      end
    end
  end

  describe "read state" do
    let(:messages) { create_list(:message, 5)}
    let(:user) { create(:user) }

    it "should mark multiple messages as read by a user" do
      messages
      Message.mark_read!(Message.limit(2), user)
      expect(Message.where("read_by_user_id is not null").count).to eq(2)
      expect(Message.where("read_at is not null").count).to eq(2)
    end

    it "should mark multiple messages as read without a user" do
      messages
      Message.mark_read!(Message.limit(2))
      expect(Message.where("read_by_user_id is null").count).to eq(messages.count)
      expect(Message.where("read_at is not null").count).to eq(2)
    end

    it "should mark a single message as read by a user" do
      messages
      message = Message.first
      Message.mark_read!(message, user)
      expect(Message.where("read_by_user_id is not null").count).to eq(1)
      expect(Message.where("read_at is not null").count).to eq(1)
    end

    it "should mark a single message as read without a user" do
      messages
      message = Message.first
      Message.mark_read!(message)
      expect(Message.where("read_by_user_id is null").count).to eq(messages.count)
      expect(Message.where("read_at is not null").count).to eq(1)
    end

  end
end
