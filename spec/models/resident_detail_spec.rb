# == Schema Information
#
# Table name: resident_details
#
#  id               :uuid             not null, primary key
#  resident_id      :uuid
#  phone1           :string
#  phone1_type      :string
#  phone1_tod       :string
#  phone2           :string
#  phone2_type      :string
#  phone2_tod       :string
#  email            :string
#  encrypted_ssn    :string
#  encrypted_ssn_iv :string
#  id_number        :string
#  id_state         :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

require 'rails_helper'

RSpec.describe ResidentDetail, type: :model do
  include_context "users"

  let(:valid_attributes) { attributes_for(:resident_detail) }

  it "can be initialized" do
    resident_detail = ResidentDetail.new(valid_attributes)
    assert resident_detail.valid?
  end

  it "encrypts the ssn" do
    resident_detail = create(:resident_detail)
    id = resident_detail.id
    ssn = resident_detail.ssn
    resident_detail = ResidentDetail.find(id)
    expect(resident_detail.ssn).to eq(ssn)
    expect(resident_detail.ssn).to_not eq(resident_detail.encrypted_ssn)
  end

  describe "associations" do
    let(:resident_detail) { create(:resident_detail) }

    it "should have a resident" do
      expect(resident_detail.resident).to be_a(Resident)
    end
  end

  describe "encryption" do
    it "provides the crypto key in the environment padded or truncated to 32 characters" do
      new_key = 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
      ENV['CRYPTO_KEY'] = new_key
      detail = ResidentDetail.new
      expect(detail.crypto_key).to eq(new_key)
      expect(detail.crypto_key.length).to eq(32)
    end

    it "provides a default crypto key if none is provided truncated to 32 characters" do
      ENV['CRYPTO_KEY'] = nil
      detail = ResidentDetail.new
      expect(detail.crypto_key).to eq(ResidentDetail::DEFAULT_CRYPTO_KEY[0..31])
    end
  end
end
