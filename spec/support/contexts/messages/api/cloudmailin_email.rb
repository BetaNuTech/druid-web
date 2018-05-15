RSpec.shared_context "cloudmailin_incoming_message" do
  include_context "users"

  let(:email_message_type) { create(:email_message_type) }
  let(:email_delivery_adapter) { create(:email_delivery_adapter) }
  let(:email_adapter_token) { email_delivery_adapter.api_token }
  let(:cloudmailin_delivery_adapter) { create(:cloudmailin_delivery_adapter) }
  let(:cloudmailin_adapter_token) { cloudmailin_delivery_adapter.api_token }
  let(:message_threadid) { SecureRandom.uuid }
  let(:message_user) { agent }
  let(:message_lead) { create(:lead, user: message_user) }
  let(:message) {
    create(:message, user: message_user, messageable: message_lead,
           threadid: message_threadid, message_type: email_message_type)
  }
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
