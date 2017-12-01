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
#

require 'rails_helper'

RSpec.describe LeadPreference, type: :model do

  let(:valid_attributes) {
    {}
  }

  it "must be associated with a Lead" do
    pref = LeadPreference.new(valid_attributes)
    pref.save
    refute(pref.valid?)
    pref.lead = create(:lead)
    pref.save
    assert(pref.valid?)
  end
end
