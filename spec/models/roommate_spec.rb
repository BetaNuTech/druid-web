# == Schema Information
#
# Table name: roommates
#
#  id            :uuid             not null, primary key
#  lead_id       :uuid
#  first_name    :string
#  last_name     :string
#  phone         :string
#  email         :string
#  relationship  :integer          default("other")
#  sms_allowed   :boolean          default(FALSE)
#  email_allowed :boolean          default(TRUE)
#  occupancy     :integer          default("resident")
#  remoteid      :string
#  notes         :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require 'rails_helper'

RSpec.describe Roommate, type: :model do
  include_context "users"

  describe "initialization" do
    it "should be valid" do
      object = create(:roommate)
      expect(object).to be_valid
    end

    it "should be 'responsible' by default" do
      object = create(:roommate)
      assert(object.responsible?)
    end
  end

  describe "validations" do
    let(:roommate) { create(:roommate) }

    it "should belong to a lead" do
      assert(roommate.valid?)
      roommate.lead = nil
      refute(roommate.valid?)
    end

    it "should have a first_name" do
      assert(roommate.valid?)
      roommate.first_name = nil
      refute(roommate.valid?)
    end

    it "should have a phone or email" do
      assert(roommate.valid?)
      assert(roommate.phone.present? && roommate.email.present?)
      roommate.phone = nil
      assert(roommate.valid?)
      roommate.email = nil
      refute(roommate.valid?)
      roommate.phone = '5555555555'
      assert(roommate.valid?)
    end

    it "should have a formatted phone number" do
      messy_phone = '(555)55 5 - 555 5 '
      clean_phone = '5555555555'
      roommate.phone = messy_phone
      roommate.validate!
      expect(roommate.phone).to eq(clean_phone)
    end
  end
end
