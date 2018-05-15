RSpec.shared_context "cloudmailin_incoming_message" do
  let(:message) { create(:message, threadid: '1234567890', message_type: create(:email_message_type)) }
  let(:cmi_message_data) {
    {
      envelope: {
        to: "foobar+#{message.threadid}@example.com",
        from: "joane.dough@example.com"
      },
      headers: {
        Subject: "Reply to Agent Message"
      },
      :plain => "Lorem ipsum dolor set amet",
      :html => "HTML Lorem ipsum dolor set amet"
    }
  }
end
