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
#  phone1         :string
#  phone2         :string
#  fax            :string
#  email          :string
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
    required_attributes = [:first_name, :phone1, :email]
    lead = Lead.new
    lead.save
    expect(lead.errors.messages.keys.sort).to eq(required_attributes.sort)
  end

  it "has a preference" do
    lead = create(:lead)
    expect(lead.preference).to be_a(LeadPreference)
  end

  it "belongs to a property" do
    property = create(:property)
    lead = create(:lead, property_id: property.id)

    expect(lead.property).to eq(property)
  end

  describe "state machine" do
    let(:lead) { create(:lead) }

    it "has a default state of 'open'" do
      lead = Lead.new
      expect(lead.state).to eq('open')
      assert lead.open?
    end

    it "transitions from open to claimed" do
      assert lead.open?
      lead.claim!
      assert lead.claimed?
    end

    it "transitions from claimed to converted" do
      assert lead.open?
      lead.claim!
      lead.convert!
      assert lead.converted?
    end

    it "transitions to disqualified" do
      lead.disqualify!
      assert lead.disqualified?
    end

    it "transitions from disqualified to open" do
      lead.disqualify!
      lead.requalify!
      assert lead.open?
    end

    it "lists valid events" do
      expect(lead.permitted_state_events).to eq([:claim, :convert, :disqualify])
      lead.claim!
      expect(lead.permitted_state_events).to eq([:abandon, :convert, :disqualify])
      lead.disqualify!
      expect(lead.permitted_state_events).to eq([:requalify])
    end

    it "lists valid states" do
      expect(lead.permitted_states).to eq([:claimed, :converted, :disqualified])
      lead.claim!
      expect(lead.permitted_states).to eq([:open, :converted, :disqualified])
    end

  end
end
