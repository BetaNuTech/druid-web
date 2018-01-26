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
#  priority       :integer          default("low")
#  phone1_type    :string
#  phone2_type    :string
#  phone1_tod     :string
#  phone2_tod     :string
#  dob            :datetime
#  id_number      :string
#  id_state       :string
#

require 'rails_helper'

RSpec.describe Lead, type: :model do
  include_context "users"

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

  describe "priorities" do
    let(:lead) { create(:lead) }

    it "should have priorities" do
      expect(Lead.priorities.keys).to eq(%w{zero low medium high urgent})
    end

    it "should have a priority value" do
      lead.priority_high!
      expect(lead.priority_value).to eq(3)
    end
  end

  describe "state machine" do
    let(:lead) { create(:lead, state: 'open') }

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

    it "optionally sets the user when claimed" do
      assert lead.open?
      lead.aasm.fire(:claim, agent)
      assert lead.save
      lead.reload
      assert lead.claimed?
      expect(lead.user).to eq(agent)
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

    it "clears user when requalified to open" do
      lead.state = 'disqualified'
      lead.user = agent
      lead.save!
      expect(lead.user).to eq(agent)
      lead.requalify!
      lead.reload
      assert lead.user.nil?
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

    describe "priorities" do
      it "should set priorty to zero when disqualified" do
        lead.priority_low!
        expect(lead.priority).to eq("low")
        lead.disqualify!
        expect(lead.priority).to eq("zero")
      end

      it "should set priorty to zero when converted" do
        lead.priority_low!
        expect(lead.priority).to eq("low")
        lead.convert!
        expect(lead.priority).to eq("zero")
      end

      it "should set priority to low when requalified" do
        lead.disqualify!
        lead.requalify!
        expect(lead.priority).to eq("low")
      end
    end

    describe "trigger_event" do

      it "should claim the lead with a user" do
        assert lead.open?
        refute lead.user.present?
        lead.trigger_event(event_name: 'claim', user: agent)
        lead.reload
        assert lead.claimed?
        expect(lead.user).to eq(agent)
      end

      it "should trigger disqualified" do
        assert lead.open?
        lead.trigger_event(event_name: 'disqualify')
        lead.reload
        assert lead.disqualified?
      end

      it "should clear the user if abandoned" do
        assert lead.open?
        lead.trigger_event(event_name: 'claim', user: agent)
        lead.reload
        expect(lead.user).to eq(agent)
        lead.trigger_event(event_name: 'abandon')
        lead.reload
        expect(lead.user).to be_nil
        assert lead.open?
      end

      it "should do nothing if the specified event is invalid/unavailable" do
        lead.disqualify!
        refute lead.trigger_event(event_name: 'open', user: agent)
      end
    end

  end
end
