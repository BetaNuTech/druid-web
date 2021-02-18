# == Schema Information
#
# Table name: residents
#
#  id          :uuid             not null, primary key
#  lead_id     :uuid
#  property_id :uuid
#  unit_id     :uuid
#  residentid  :string
#  status      :string
#  dob         :date
#  title       :string
#  first_name  :string
#  middle_name :string
#  last_name   :string
#  address1    :string
#  address2    :string
#  city        :string
#  state       :string
#  zip         :string
#  country     :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

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
      expect(resident.errors.full_messages.last).to eq(Resident::INVALID_UNIT_PROPERTY_ERROR)
    end

    it "must have a unique residentid" do
      resident2 = create(:resident)
      assert resident.valid?
      resident.residentid = resident2.residentid
      refute resident.valid?
    end

    it "must have a status" do
      assert resident.valid?
      resident.status = "former"
      assert resident.valid?
      resident.status = "invalid status"
      refute resident.valid?
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
    #it "has a detail (ResidentDetail) which is assigned on initialization" do
      #resident = Resident.new
      #expect(resident.detail).to be_a(ResidentDetail)
    #end

    it "accepts nested attributes for ResidentDetail" do
      params = {
        resident: {
          first_name: "Joe",
          detail_attributes: {
            phone1: "555-555-5555"
          }
        }
      }
      resident = Resident.new
      resident.attributes = params[:resident]
      expect(resident.first_name).to eq(params[:resident][:first_name])
      expect(resident.detail.phone1).to eq(params[:resident][:detail_attributes][:phone1])
    end
  end

  describe "callbacks" do
    it "assigns a random and unique residentid" do
      resident = build(:resident)
      resident.residentid = nil
      resident.save!
      expect(resident.residentid).to_not be_nil
    end
  end

  describe "instance methods" do
    it "returns a full concatenated name" do
      resident = build(:resident)
      expected_name = [resident.title, resident.first_name, resident.middle_name, resident.last_name].join(" ")
      expect(resident.name).to eq(expected_name)
    end

    it "returns a salutation" do
      resident = build(:resident)
      expected_name = [resident.title, resident.last_name].join(" ")
      expect(resident.salutation).to eq(expected_name)
    end
  end

end
