# == Schema Information
#
# Table name: lead_preferences
#
#  id          :uuid             not null, primary key
#  lead_id     :uuid
#  min_area    :integer
#  max_area    :integer
#  min_price   :decimal(, )
#  max_price   :decimal(, )
#  move_in     :datetime
#  baths       :decimal(, )
#  pets        :boolean
#  smoker      :boolean
#  washerdryer :boolean
#  notes       :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  beds        :integer
#  raw_data    :text
#

require 'rails_helper'

RSpec.describe LeadPreference, type: :model do

  let(:valid_attributes) {
    {
      min_area: 1,
      max_area: 2,
      min_price: 1,
      max_price: 2
    }
  }

  it "must be associated with a Lead" do
    pref = LeadPreference.new(valid_attributes)
    pref.save
    refute(pref.valid?)
    pref.lead = create(:lead)
    pref.save
    assert(pref.valid?)
  end

  it "must have a min_area smaller than max_area" do
    min, max = [100, 200]
    lead = create(:lead)
    pref = lead.preference

    validate_min_max = Proc.new { |pref, min,max,is_valid|
      pref.min_area = min
      pref.max_area = max
      pref.validate
      expect(pref.valid?).to eq(is_valid)
    }

    # Valid where min < max
    validate_min_max.call(pref, 100, 200, true)

    # Valid where max is nil
    validate_min_max.call(pref, 100, nil, true)

    # Invalid where min > max
    validate_min_max.call(pref, 200, 100, false)
  end

  it "must have a min_price smaller than max_price" do
    min, max = [100, 200]
    lead = create(:lead)
    pref = lead.preference

    validate_min_max = Proc.new { |pref, min,max,is_valid|
      pref.min_price = min
      pref.max_price = max
      pref.validate
      expect(pref.valid?).to eq(is_valid)
    }

    # Valid where min < max
    validate_min_max.call(pref, 100, 200, true)

    # Valid where max is nil
    validate_min_max.call(pref, 100, nil, true)

    # Invalid where min > max
    validate_min_max.call(pref, 200, 100, false)
  end

  it "has a unit system" do
    pref = LeadPreference.new
    expect(pref.unit_system).to eq(:imperial)
  end
end
