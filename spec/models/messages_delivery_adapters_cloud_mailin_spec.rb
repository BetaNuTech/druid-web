require 'rails_helper'

RSpec.describe Messages::DeliveryAdapters::CloudMailin do
  include_context "cloudmailin_incoming_message"
  include_context "messaging"

  describe "initialization" do
    it "can be initialized with a data hash" do
      adapter = Messages::DeliveryAdapters::CloudMailin.new(cmi_message_data)
      assert adapter.data.present?
    end
  end

  describe "parse" do
    it "returns a Result Object" do
      adapter = Messages::DeliveryAdapters::CloudMailin.new(cmi_message_data)
      result = adapter.parse

      assert result.is_a?(Messages::Receiver::Result)
      assert result.status == :ok
      assert result.message.is_a?(Hash)
      assert result.errors.empty?
    end
  end

end
