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

  describe "associations" do
    let(:property) { create(:property) }
    let(:lead) { create(:lead, user: agent, property: property) }
    let(:lead2) { create(:lead, property: property) }

    it "returns a list of leads assigned to an agent/user" do
      lead; lead2
      expect(property.leads.for_agent(agent)).to eq([lead])
    end

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

    it "lists 'active' leads" do
      expect(Lead.active).to eq([lead])
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

    describe "full-text search" do
      let(:lead1) { create(:lead,
                           first_name: 'first_name_1', last_name: 'last_name_1',
                           referral: 'referral_1', notes: 'notes_1',
                           phone1: 'phone1_1', phone2: 'phone2_1', fax: 'fax_1',
                           email: 'email_1', id_number: 'id_number_1'
                          )}
      let(:lead2) { create(:lead,
                           first_name: 'first_name_2', last_name: 'last_name_2',
                           referral: 'referral_2', notes: 'notes_2',
                           phone1: 'phone1_2', phone2: 'phone2_2', fax: 'fax_2',
                           email: 'email_2', id_number: 'id_number_2'
                          )}
      let(:lead3) { create(:lead,
                           first_name: 'first_name_3', last_name: 'last_name_3',
                           referral: 'referral_3', notes: 'notes_3',
                           phone1: 'phone1_3', phone2: 'phone2_3', fax: 'fax_3',
                           email: 'email_3', id_number: 'id_number_3'
                          )}

      before do
        lead1; lead2; lead3
      end

      it "searches by first_name" do
        results = Lead.search_for("first_name")
        expect(results.count).to eq(3)
        results = Lead.search_for('first_name_1')
        expect(results.count).to eq(1)
        expect(results.first.id).to eq(lead1.id)
        results = Lead.search_for('first_name_2')
        expect(results.count).to eq(1)
        expect(results.first.id).to eq(lead2.id)
      end

      it "searches by last_name" do
        results = Lead.search_for("last_name")
        expect(results.count).to eq(3)
        results = Lead.search_for('last_name_1')
        expect(results.count).to eq(1)
        expect(results.first.id).to eq(lead1.id)
        results = Lead.search_for('last_name_2')
        expect(results.count).to eq(1)
        expect(results.first.id).to eq(lead2.id)
      end

      it "searches by referral" do
        results = Lead.search_for("referral")
        expect(results.count).to eq(3)
        results = Lead.search_for('referral_1')
        expect(results.count).to eq(1)
        expect(results.first.id).to eq(lead1.id)
        results = Lead.search_for('referral_2')
        expect(results.count).to eq(1)
        expect(results.first.id).to eq(lead2.id)
      end

      it "searches by notes" do
        results = Lead.search_for("notes")
        expect(results.count).to eq(3)
        results = Lead.search_for('notes_1')
        expect(results.count).to eq(1)
        expect(results.first.id).to eq(lead1.id)
        results = Lead.search_for('notes_2')
        expect(results.count).to eq(1)
        expect(results.first.id).to eq(lead2.id)
      end

      it "searches by phone1" do
        results = Lead.search_for("phone1")
        expect(results.count).to eq(3)
        results = Lead.search_for('phone1_1')
        expect(results.count).to eq(1)
        expect(results.first.id).to eq(lead1.id)
        results = Lead.search_for('phone1_2')
        expect(results.count).to eq(1)
        expect(results.first.id).to eq(lead2.id)
      end

      it "searches by notes" do
        results = Lead.search_for("notes")
        expect(results.count).to eq(3)
        results = Lead.search_for('notes_1')
        expect(results.count).to eq(1)
        expect(results.first.id).to eq(lead1.id)
        results = Lead.search_for('notes_2')
        expect(results.count).to eq(1)
        expect(results.first.id).to eq(lead2.id)
      end

      it "searches by fax" do
        results = Lead.search_for("fax")
        expect(results.count).to eq(3)
        results = Lead.search_for('fax_1')
        expect(results.count).to eq(1)
        expect(results.first.id).to eq(lead1.id)
        results = Lead.search_for('fax_2')
        expect(results.count).to eq(1)
        expect(results.first.id).to eq(lead2.id)
      end

      it "searches by email" do
        results = Lead.search_for("email")
        expect(results.count).to eq(3)
        results = Lead.search_for('email_1')
        expect(results.count).to eq(1)
        expect(results.first.id).to eq(lead1.id)
        results = Lead.search_for('email_2')
        expect(results.count).to eq(1)
        expect(results.first.id).to eq(lead2.id)
      end

      it "searches by id_number" do
        results = Lead.search_for("id_number")
        expect(results.count).to eq(3)
        results = Lead.search_for('id_number_1')
        expect(results.count).to eq(1)
        expect(results.first.id).to eq(lead1.id)
        results = Lead.search_for('id_number_2')
        expect(results.count).to eq(1)
        expect(results.first.id).to eq(lead2.id)
      end
    end

  end

  describe "having comments" do
    let(:lead) { create(:lead) }
    let(:comment_attributes) { {content: 'foobar'} }

    it "has many comments" do
      expect {
        lead.comments.build(comment_attributes).save!
      }.to change{Note.count}.by(1)
      lead.reload
      expect(lead.comments.count).to eq(1)
    end

  end
end
