RSpec.shared_context "message_templates" do
  include_context 'users'
  include_context 'messaging'

  let(:property1_manager1) { manager }
  let(:property1_agent1) { agent }
  let(:property2_agent2) { agent2 }

  let(:manager1_shared_email_template) { create(:message_template, message_type: email_message_type, user: property1_manager1, shared: true) }
  let(:manager1_shared_sms_template) { create(:message_template, message_type: sms_message_type, user: property1_manager1, shared: true) }
  let(:manager1_private_template) { create(:message_template, message_type: email_message_type, user: property1_manager1, shared: false) }

  let(:agent1_shared_email_template) { create(:message_template, message_type: email_message_type, user: property1_agent1, shared: true) }
  let(:agent1_shared_sms_template) { create(:message_template, message_type: sms_message_type, user: property1_agent1, shared: true) }
  let(:agent1_private_template) { create(:message_template, message_type: email_message_type, user: property1_agent1, shared: false) }
  let(:agent2_shared_email_template) { create(:message_template, message_type: email_message_type, user: property2_agent2, shared: true) }
  let(:agent2_shared_sms_template) { create(:message_template, message_type: sms_message_type, user: property2_agent2, shared: true) }
  let(:agent2_private_template) { create(:message_template, message_type: email_message_type, user: property2_agent2, shared: false) }

  let(:all_message_templates) {
    [
      manager1_shared_email_template,
      manager1_shared_sms_template,
      manager1_private_template,
      agent1_shared_email_template,
      agent1_shared_sms_template,
      agent1_private_template,
      agent2_shared_email_template,
      agent2_shared_sms_template,
      agent2_private_template,
    ]
  }

  before do
    #MessageTemplate.destroy_all
    all_message_templates
  end
end
