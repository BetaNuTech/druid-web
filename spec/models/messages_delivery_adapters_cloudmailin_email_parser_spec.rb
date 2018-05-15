require 'rails_helper'

RSpec.describe Messages::DeliveryAdapters::Cloudmailin::EmailParser do
  include_context "cloudmailin_incoming_message"

  describe "match" do
    it "always returns true" do
      assert Messages::DeliveryAdapters::Cloudmailin::EmailParser.match?(nil)
    end

    it "returns relevant Message attributes from CloudMailin email post data" do
      result = Messages::DeliveryAdapters::Cloudmailin::EmailParser.parse(cmi_message_data)

      assert result[:messageable_id] == message.messageable_id
      assert result[:messageable_type] == 'Lead'
      assert result[:user_id] == message.user_id
      assert result[:state] == 'sent'
      assert result[:senderid] = cmi_data[:envelope][:from]
      assert result[:recipientid] = cmi_data[:envelope][:to]
      assert result[:message_template_id] == nil
      assert result[:subject] == cmi_data[:headers][:Subject]
      assert result[:body] == cmi_data[:plain]
      assert result[:delivered_at].present?
      assert result[:message_type_id] == MessageType.email.try(:id)
      assert result[:threadid] == message.threadid
    end
  end
end
