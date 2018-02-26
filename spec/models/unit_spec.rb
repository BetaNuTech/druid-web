# == Schema Information
#
# Table name: units
#
#  id             :uuid             not null, primary key
#  property_id    :uuid
#  unit_type_id   :uuid
#  rental_type_id :uuid
#  unit           :string
#  floor          :integer
#  sqft           :integer
#  bedrooms       :integer
#  description    :text
#  address1       :string
#  address2       :string
#  city           :string
#  state          :string
#  zip            :string
#  country        :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

require 'rails_helper'

RSpec.describe Unit, type: :model do
  let(:unit) { build(:unit) }
  it "can be initialized" do
    expect(unit).to be_a(Unit)
  end

  it "can be saved" do
    assert unit.save
  end

  it "can be updated" do
    new_unit = "Foobar123"
    unit.save!
    expect {
      unit.unit = new_unit
      unit.save
    }.to change{unit.unit}
  end

  it "has a unique name within a property" do
    unit.save!
    unit2 = build(:unit, unit: unit.unit)
    assert unit2.save

    # Case insensitive
    unit2.unit = unit2.unit.upcase

    unit2.property = unit.property
    refute unit2.save
  end

  it "has ALLOWED_PARAMS" do
    expect(Unit::ALLOWED_PARAMS).to eq([:id, :property_id, :unit_type_id, :rental_type_id, :unit, :floor, :sqft, :bedrooms, :address1, :address2, :city, :state, :zipcode, :country])
  end

  describe "associations" do
    it "has a property" do
      expect(unit.property).to be_a(Property)
    end

    it "has a rental_type" do
      expect(unit.rental_type).to be_a(RentalType)
    end

    it "has a unit_type" do
      expect(unit.unit_type).to be_a(UnitType)
    end

    it "delegates name to property" do
      expect(unit.property_name).to eq(unit.property.name)
    end

    it "delegates name to unit_type" do
      expect(unit.unit_type_name).to eq(unit.unit_type.name)
    end

    it "delegates name to rental_type" do
      expect(unit.rental_type_name).to eq(unit.rental_type.name)
    end
  end

end
