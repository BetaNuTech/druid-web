# == Schema Information
#
# Table name: leads
#
#  id             :uuid             not null, primary key
#  user_id        :uuid
#  lead_source_id :uuid
#  title          :string
#  first_name     :string
#  last_name      :string
#  referral       :string
#  state          :string
#  notes          :text
#  first_comm     :datetime
#  last_comm      :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  property_id    :uuid
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

  it "can provide a full name including title, first_name, and last_name" do
    lead = create(:lead)
    expect(lead.name).to match(lead.first_name)
    expect(lead.name).to match(lead.last_name)
    expect(lead.name).to match(lead.title)
  end

  it "validates the presence of required attributes" do
    required_attributes = [:first_name, :last_name]
    lead = Lead.new
    lead.save
    expect(lead.errors.messages.keys.sort).to eq(required_attributes.sort)
  end

  it "has a preference" do
    lead = create(:lead)
    expect(lead.preference).to be_a(LeadPreference)
  end
end
