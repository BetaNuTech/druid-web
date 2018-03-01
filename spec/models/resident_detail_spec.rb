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
end
