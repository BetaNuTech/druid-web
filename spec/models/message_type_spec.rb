# == Schema Information
#
# Table name: message_types
#
#  id          :uuid             not null, primary key
#  name        :string           not null
#  description :text
#  active      :boolean          default(TRUE), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  html        :boolean          default(FALSE)
#

require 'rails_helper'

RSpec.describe MessageType, type: :model do
  it "can be initialized" do
    message_type = build(:message_type)
  end

  it "can load seed data" do
    MessageType.destroy_all
    expect {
      MessageType.load_seed_data
    }.to change{MessageType.count}.by(2)
  end

  describe "scopes" do
    it "can query based on 'active'" do
      create(:message_type, active: false)
      create(:message_type, active: true)

      expect(MessageType.count).to eq(2)
      expect(MessageType.active.count).to eq(1)
    end
  end
end
