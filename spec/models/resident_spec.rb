require 'rails_helper'

RSpec.describe Resident, type: :model do
  include_context "users"

  let(:valid_attributes) { build(:resident).attributes }

  it "can be initialized" do
    resident = Resident.new(valid_attributes)
    expect(resident).to be_a(Resident)
  end

  it "can be created" do
    resident = Resident.new(valid_attributes)
    assert resident.save
  end

  describe "validations" do
    let(:resident) { build(:resident)}
    let(:property) { resident.property }

    it "must have a unit that belongs to the same property" do
      assert resident.valid?
      property2 = create(:property)
      unit = resident.unit
      unit.property = property2
      unit.save!
      resident.unit = unit
      refute resident.valid?
      expect(resident.errors.first.last).to eq(Resident::INVALID_UNIT_PROPERTY_ERROR)
    end

    it "must have a unique residentid" do
      resident2 = create(:resident)
      assert resident.valid?
      resident.residentid = resident2.residentid
      refute resident.valid?
    end

    it "must have a status" do
      assert resident.valid?
      resident.status = nil
      refute resident.valid?
    end

    it "must have a first_name" do
      assert resident.valid?
      resident.first_name = nil
      refute resident.valid?
    end

    it "must have a last_name" do
      assert resident.valid?
      resident.last_name = nil
      refute resident.valid?
    end
  end

  describe "associations" do
    it "has a detail (ResidentDetail)"
    it "accepts nested attributes for ResidentDetail"
  end

end
