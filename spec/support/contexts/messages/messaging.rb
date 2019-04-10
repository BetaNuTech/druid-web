RSpec.shared_context "messaging" do
  let(:email_message_type) { MessageType.email || create(:email_message_type) }
  let(:sms_message_type) { MessageType.sms || create(:sms_message_type) }
  let(:email_message_adapter) { create(:email_delivery_adapter, message_type: email_message_type)}
  let(:sms_message_adapter) { create(:sms_delivery_adapter, message_type: sms_message_type)}
  let(:email_delivery_adapter) {
    MessageDeliveryAdapter.where(slug: 'Actionmailer').first ||
    MessageDeliveryAdapter.create!( name: 'ActionMailer', slug: 'Actionmailer', active: true,
                                     message_type: email_message_type) }

  before do
    email_message_adapter
    sms_message_adapter
    email_delivery_adapter
  end
end
