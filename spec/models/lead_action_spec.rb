# == Schema Information
#
# Table name: lead_actions
#
#  id          :uuid             not null, primary key
#  name        :string
#  description :string
#  active      :boolean          default(TRUE)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#


require 'rails_helper'

RSpec.describe LeadAction, type: :model do

  it "can be initialized" do
    lead_action = build(:lead_action)
  end

  it "can be saved" do
    lead_action = build(:lead_action)
    assert lead_action.save
  end

  it "can be updated" do
    new_name = 'foobar'
    lead_action = create(:lead_action)
    expect {
      lead_action.name = new_name
      lead_action.save
    }.to change{lead_action.name}
  end

  it "must have a name" do
    lead_action = build(:lead_action)
    assert lead_action.valid?
    lead_action.name = nil
    refute lead_action.valid?
  end

  it "has a unique name" do
    lead_action_name = 'foobar'
    lead_action = create(:lead_action, name: lead_action_name)
    lead_action2 = build(:lead_action, name: lead_action_name)
    refute lead_action2.valid?
  end

  it "has ALLOWED_PARAMS" do
    expect(LeadAction::ALLOWED_PARAMS).to eq([:id, :name, :description,:active])
  end

end
