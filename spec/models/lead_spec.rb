# == Schema Information
#
# Table name: leads
#
#  id                  :uuid             not null, primary key
#  user_id             :uuid
#  lead_source_id      :uuid
#  lead_preferences_id :uuid
#  title               :string
#  first_name          :string
#  last_name           :string
#  referral            :string
#  state               :string
#  notes               :text
#  first_comm          :datetime
#  last_comm           :datetime
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#

require 'rails_helper'

RSpec.describe Lead, type: :model do
  it "can be initialized" do
    lead = build(:lead)
  end

  it "can be saved" do
    lead = build(:lead)
    assert lead.save
  end

  it "can be updated" do
    lead = create(:lead)
    lead.reload
    lead.notes = 'Foo'
    lead.save!
    lead.reload
    expect(lead.notes).to eq('Foo')
  end
end
