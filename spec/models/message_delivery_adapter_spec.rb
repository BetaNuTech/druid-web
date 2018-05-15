# == Schema Information
#
# Table name: message_delivery_adapters
#
#  id              :uuid             not null, primary key
#  message_type_id :uuid             not null
#  slug            :string           not null
#  name            :string           not null
#  description     :text
#  active          :boolean          default(TRUE), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  api_token       :string
#

require 'rails_helper'

RSpec.describe MessageDeliveryAdapter, type: :model do
  describe "initialization" do
    it "can be initialized" do
      msd = build(:message_delivery_adapter)
      assert msd.save
    end
  end
  describe "associations" do
    it "has an associated message_type" do
      msd = create(:message_delivery_adapter)
      expect(msd.message_type).to be_a(MessageType)
    end
  end

  describe "validations" do
    let(:message_delivery_adapter) { create(:message_delivery_adapter) }
    it "always has a name" do
      assert message_delivery_adapter.valid?
      message_delivery_adapter.name = nil
      refute message_delivery_adapter.valid?
    end
    it "always has an active flag" do
      assert message_delivery_adapter.valid?
      message_delivery_adapter.active = nil
      refute message_delivery_adapter.valid?
    end
    it "always has a unique slug" do
      assert message_delivery_adapter.valid?

      message_delivery_adapter2 = create(:message_delivery_adapter)
      message_delivery_adapter.slug = message_delivery_adapter2.slug
      refute message_delivery_adapter.valid?

      message_delivery_adapter.slug = nil
      refute message_delivery_adapter.valid?
    end
    it "always has a message_type_id" do
      assert message_delivery_adapter.valid?
      message_delivery_adapter.message_type = nil
      refute message_delivery_adapter.valid?
    end
    it "always has a unique api_token" do
      assert message_delivery_adapter.valid?
      message_delivery_adapter2 = create(:message_delivery_adapter)
      message_delivery_adapter.api_token = message_delivery_adapter2.api_token
      refute message_delivery_adapter.valid?
    end
  end

  describe "callbacks" do
    it "generates a missing api_token" do
      mda = build(:message_delivery_adapter)
      mda.api_token = nil
      assert mda.api_token.nil?
      assert mda.valid?
      refute mda.api_token.nil?
    end
  end
end
