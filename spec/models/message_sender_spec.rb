require 'rails_helper'

RSpec.describe Messages::Sender do
  include_context 'users'
  include_context 'messaging'

  let(:email_message_body) { 'Test EMAIL message BODY' }
  let(:email_message_subject) { 'Test EMAIL message SUBJECT' }
  let(:message) {
    message = Message.new_message(
      message_type: email_message_type,
      from: agent, to: lead,
      body: email_message_body, subject: email_message_subject)
    message.save!; message }
  let(:lead) { create(:lead, user: agent, property: agent.property) }

  it "automatically sets 'read' status on outgoing messages" do
    message.deliver
    expect(message.read_at).to_not be_nil
    expect(message.read_by_user_id).to eq(agent.id)
  end

  it "sets status and delivery attributes upon delivery of a message" do
    message.deliver
    refute(message.incoming)
  end

end
