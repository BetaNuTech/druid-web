# == Schema Information
#
# Table name: rental_types
#
#  id         :uuid             not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rails_helper'

RSpec.describe RentalType, type: :model do
  it "can be initialized" do
    rt = build(:rental_type)
    expect(rt).to be_a(RentalType)
  end

  describe "validations" do
    it "requires a name" do
      rt = build(:rental_type)
      assert rt.valid?
      rt.name = ''
      refute rt.valid?
    end

    it "require a unique name (case insensitive)" do
      name = "Foobar"
      name2 = "foobar"
      name3 = "Quux"
      rt1 = create(:rental_type, name: name)
      rt2 = build(:rental_type, name: name)
      refute rt2.valid?
      rt2.name = name2
      refute rt2.valid?
      rt2.name = name3
      assert rt2.valid?
    end
  end
end
