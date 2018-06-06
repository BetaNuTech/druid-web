RSpec.shared_context "twilio_incoming_message" do
  include_context "users"

  let(:sms_message_type) { MessageType.sms || create(:sms_message_type) }
  #let(:sms_delivery_adapter) { create(:sms_delivery_adapter) }
  let(:sms_adapter_token) { sms_delivery_adapter.api_token }
  let(:twilio_delivery_adapter) { create(:sms_delivery_adapter) }
  let(:twilio_adapter_token) { twilio_delivery_adapter.api_token }
  let(:sms_message_threadid) { Message.new_threadid }
  let(:sms_message_user) { agent }
  let(:sms_message_lead) { create(:lead, user: message_user, phone1: '555-555-5555', phone1_type: 'Cell' ) }
  let(:sms_message) {
    twilio_delivery_adapter
    msg = Message.new_message( to: sms_message_lead,
                               from: sms_message_user,
                               subject: 'None',
                               body: 'Test SMS Message',
                               message_type: sms_message_type,
                               threadid: sms_message_threadid
                             )
    msg.save!
    msg.deliver!
    msg
  }
  let(:twilio_message_data) {
    {
      :token => twilio_adapter_token,
      'From' => Message.format_phone(sms_message_lead.phone1),
      'To' => '5555555555',
      'Body' => 'This is SMS data from Twilio'
    }
  }
end
