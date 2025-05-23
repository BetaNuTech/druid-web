require 'rails_helper'

RSpec.describe IncomingMessagesUserChannel, type: :channel do
  include_context 'users'
  include_context 'team_members'
  include_context 'messaging'

  let(:user) { team1_agent1; team1_agent1.switch_setting!(:view_all_messages, true); team1_agent1.switch_setting!(:message_web_notifications, true); team1_agent1 }
  let(:user2) { team1_agent2 }
  let(:lead) { create(:lead, property: user.property, user: user, state: 'prospect') }
  let(:property) { user.property }
  let(:property2) { user2.property }
  let(:user_stream) { source_message.user_incoming_messages_stream_name}
  let(:source_message) {
    message = Message.new_message(from: lead, to: user, message_type: MessageType.email, subject: 'Email from Lead', body: 'Body content' )
    message.save!
    message
  }

  describe "subscription for authenticated user" do
    before do
      stub_connection current_user: user
    end

    it "successfully subscribes to own stream" do
      assert(user.setting_enabled?(:message_web_notifications))
      subscribe
      expect(subscription).to be_confirmed
      expect(subscription.current_user).to eq user
    end

    it "streams broadcasts" do
      subscribe
      expect {
        source_message.broadcast_to_streams
      }.to have_broadcasted_to(user_stream)
    end

  end
end
