# == Schema Information
#
# Table name: unit_types
#
#  id         :uuid             not null, primary key
#  name       :string
#  active     :boolean          default(TRUE)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

RSpec.describe UnitType, type: :model do
  include_context "roles"

  let(:new_unit_type) { build(:unit_type) }

  it "can be initialized" do
    new_unit_type
    expect(new_unit_type).to be_a(UnitType)
  end

  it "can be saved" do
    assert new_unit_type.save
  end

  it "can be updated" do
    new_unit_type.save!
    expect{
      new_unit_type.name = 'Foobar'
      new_unit_type.save!
    }.to change{new_unit_type.name}
  end

  describe "validations" do
    it "must have a name" do
      new_unit_type.save!
      assert new_unit_type.valid?
      new_unit_type.name = nil
      refute new_unit_type.valid?
    end

    it "has a unique name" do
      name_lc = 'foobar'
      name_mc = 'Foobar'
      unittype1 = create(:unit_type, name: name_lc)
      unittype2 = build(:unit_type, name: name_mc)
      assert unittype1.valid?
      refute unittype2.valid?
    end
  end


end
