# == Schema Information
#
# Table name: reasons
#
#  id          :uuid             not null, primary key
#  name        :string
#  description :string
#  active      :boolean
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'rails_helper'

RSpec.describe Reason, type: :model do

  it "can be initialized" do
    reason = build(:reason)
  end

  it "can be saved" do
    reason = build(:reason)
    assert reason.save
  end

  it "can be updated" do
    new_name = 'foobar'
    reason = create(:reason)
    expect {
      reason.name = new_name
      reason.save
    }.to change{reason.name}
  end

  it "must have a name" do
    reason = build(:reason)
    assert reason.valid?
    reason.name = nil
    refute reason.valid?
  end

  it "has a unique name" do
    reason_name = 'foobar'
    reason = create(:reason, name: reason_name)
    reason2 = build(:reason, name: reason_name)
    refute reason2.valid?
  end

  it "has ALLOWED_PARAMS" do
    expect(Reason::ALLOWED_PARAMS).to eq([:id, :name, :description,:active])
  end

end
