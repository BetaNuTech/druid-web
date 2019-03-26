# == Schema Information
#
# Table name: leads
#
#  id                  :uuid             not null, primary key
#  user_id             :uuid
#  lead_source_id      :uuid
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
#  property_id         :uuid
#  phone1              :string
#  phone2              :string
#  fax                 :string
#  email               :string
#  priority            :integer          default("low")
#  phone1_type         :string
#  phone2_type         :string
#  phone1_tod          :string
#  phone2_tod          :string
#  dob                 :datetime
#  id_number           :string
#  id_state            :string
#  remoteid            :string
#  middle_name         :string
#  conversion_date     :datetime
#  call_log            :json
#  call_log_updated_at :datetime
#  classification      :integer
#  follow_up_at        :datetime
#

require 'rails_helper'

RSpec.describe Lead, type: :model do
  include_context "users"
  include_context "engagement_policy"

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

  describe "lead transitions" do
    let(:lead) { create(:lead)}

    it "has many lead transitions" do
      lead.lead_transitions << build(:lead_transition)
      assert lead.save
      expect(lead.lead_transitions.first).to be_a(LeadTransition)
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

    it "transitions from open to prospect" do
      assert lead.open?
      lead.claim!
      assert lead.prospect?
    end

    it "optionally sets the user when prospect" do
      assert lead.open?
      lead.aasm.fire(:claim, agent)
      assert lead.save
      lead.reload
      assert lead.prospect?
      expect(lead.user).to eq(agent)
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
      expect(lead.permitted_state_events.sort).to eq([:claim, :disqualify, :postpone].sort)
      lead.claim!
      expect(lead.state).to eq('prospect')
      expect(lead.permitted_state_events.sort).to eq([:abandon, :disqualify, :release, :apply, :postpone].sort)
      lead.disqualify!
      expect(lead.permitted_state_events).to eq([:requalify])
    end

    it "lists valid states" do
      expect(lead.permitted_states).to eq([:prospect, :disqualified, :future])
      lead.claim!
      expect(lead.state).to eq('prospect')
      expect(lead.permitted_states.sort).to eq([:application, :abandoned, :disqualified, :open, :future].sort)
    end

    it "lists 'active' leads" do
      expect(Lead.active).to eq([lead])
    end

    describe "lead_transitions" do
      let(:memo) { 'Lead transition memo 1'}

      it "creates a lead transtion from nothing to open on create" do
        expect(LeadTransition.count).to eq(0)
        lead
        expect(LeadTransition.count).to eq(1)
        xtn = lead.lead_transitions.first
        expect(xtn.last_state).to eq('none')
        expect(xtn.current_state).to eq('open')
      end

      it "creates a lead_transition record upon state change" do
        expect(lead.lead_transitions.count).to eq (1)
        lead.transition_memo = memo
        lead.classification = 'lead'
        lead.claim!
        lead.reload

        expect(lead.state).to eq('prospect')
        expect(lead.lead_transitions.count).to eq(2)
        lead_transition = lead.lead_transitions.order(created_at: :desc).first
        expect(lead_transition.last_state).to eq('open')
        expect(lead_transition.current_state).to eq(lead.state)
        expect(lead_transition.classification).to eq('lead')
        expect(lead_transition.memo).to eq(memo)

        memo2 = 'Lead transition memo 2'
        lead_classification = 'vendor'
        lead.classification = lead_classification
        lead.transition_memo = memo2
        expect(lead.state).to eq('prospect')
        lead.disqualify!
        lead.reload

        expect(lead.state).to eq('disqualified')
        expect(lead.lead_transitions.count).to eq(3)
        lead_transition = lead.lead_transitions.order('created_at desc').first
        expect(lead_transition.last_state).to eq('prospect')
        expect(lead_transition.current_state).to eq(lead.state)
        expect(lead_transition.classification).to eq(lead_classification)
        expect(lead_transition.memo).to eq(memo2)
      end

      it "creates a lead_transition record without transition_memo or classification set" do
        lead.claim!
        lead.reload
        expect(lead.lead_transitions.count).to eq(2)
        lead_transition = lead.lead_transitions.order(created_at: :desc).first
        expect(lead_transition.last_state).to eq('open')
        expect(lead_transition.current_state).to eq(lead.state)
        expect(lead_transition.classification).to eq('lead')
        expect(lead_transition.memo).to be_nil
      end

      it "cleans up record tasks and agent association upon 'postpone'" do
        seed_engagement_policy
        lead.trigger_event(event_name: 'claim', user: agent)
        lead.reload
        assert(lead.scheduled_actions.count > 0)
        expect(lead.user).to eq(agent)
        lead.postpone!
        lead.reload
        expect(lead.scheduled_actions.count).to eq(0)
        expect(lead.user).to be_nil
        expect(lead.priority).to eq('low')
      end
    end

    describe "priorities" do
      it "should set priorty to zero when disqualified" do
        lead.priority_low!
        expect(lead.priority).to eq("low")
        lead.disqualify!
        expect(lead.priority).to eq("zero")
      end

      it "should set priorty to zero when lodged" do
        lead.priority_low!
        lead.state = "movein"
        lead.save!
        expect(lead.priority).to eq("low")
        lead.lodge!
        expect(lead.priority).to eq("zero")
      end

      it "should set priority to low when requalified" do
        lead.disqualify!
        lead.requalify!
        expect(lead.priority).to eq("low")
      end
    end

    describe "scheduled actions" do
      include_context "engagement_policy"
      include_context "team_members"

      before(:each) do
        seed_engagement_policy
      end

      it "should clear all old tasks when abandoned" do
        ScheduledAction.destroy_all
        agent = team1_agent1
        property = agent.properties.first
        lead.property = property
        lead.trigger_event(event_name: 'claim', user: agent)
        lead.reload
        expect(lead.scheduled_actions.count).to be > 0
        lead.abandon!
        lead.reload
        expect(lead.scheduled_actions.count).to eq(0)
      end
    end

    describe "trigger_event" do

      it "should claim the lead with a user" do
        assert lead.open?
        refute lead.user.present?
        lead.trigger_event(event_name: 'claim', user: agent)
        lead.reload
        assert lead.prospect?
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
        assert lead.abandoned?
      end

      it "should do nothing if the specified event is invalid/unavailable" do
        lead.disqualify!
        refute lead.trigger_event(event_name: 'open', user: agent)
      end

      it "should set the conversion date after transition to 'resident'" do
        lead.state = 'movein'
        lead.save!
        refute(lead.conversion_date.present?)
        lead.trigger_event(event_name: 'lodge', user: agent)
        lead.reload
        assert(lead.conversion_date.present?)
      end
    end

    describe "full-text search" do
      let(:lead1) { create(:lead,
                           first_name: 'first_name_1', last_name: 'last_name_1',
                           referral: 'referral_1', notes: 'notes_1',
                           phone1: '5555555555', phone2: 'phone2_1', fax: 'fax_1',
                           email: 'email_1', id_number: 'id_number_1'
                          )}
      let(:lead2) { create(:lead,
                           first_name: 'first_name_2', last_name: 'last_name_2',
                           referral: 'referral_2', notes: 'notes_2',
                           phone1: '5555555550', phone2: 'phone2_2', fax: 'fax_2',
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
        results = Lead.search_for('5555555555')
        expect(results.count).to eq(1)
        expect(results.first.id).to eq(lead1.id)
        results = Lead.search_for('5555555550')
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

  describe "messaging helpers" do
    let(:lead) { create(:lead) }
    let(:sms_message_type) {create(:sms_message_type)}
    let(:email_message_type) {create(:email_message_type)}

    it "returns message_template information" do
      expected_data_keys = %w{ lead_name lead_floorplan agent_name agent_title
                               property_name property_address property_address_html
                               property_city property_amenities property_website
                               property_phone property_school_district property_application_url
                               html_email_header_image email_bluestone_logo email_housing_logo
                               email_unsubscribe_link }
      attrs = lead.message_template_data
      assert attrs.is_a?(Hash)
      expect(attrs.keys).to eq(expected_data_keys)
    end

    it "returns the preferred message_email_destination" do
      expect(lead.message_email_destination).to eq(lead.email)
    end

    describe "returning message_sms_destination" do
      describe "with a Cell number" do
        it "returns a Cell phone number as the  message_sms_destination" do
          lead.phone1 = "555-555-5511"
          lead.phone2 = "555-555-5512"
          lead.phone1_type = 'Cell'
          lead.phone2_type = 'Home'
          expect(lead.message_sms_destination).to eq(Message.format_phone(lead.phone1))
          lead.phone1_type = 'Home'
          lead.phone2_type = 'Cell'
          expect(lead.message_sms_destination).to eq(Message.format_phone( lead.phone2 ))
        end

      end

      describe "with only a non-cell number" do
        it "returns the first known phone number" do
          lead.phone1 = nil
          lead.phone1_type = nil
          lead.phone2 = "555-555-5512"
          lead.phone2_type = 'Home'
          expect(lead.message_sms_destination).to eq(Message.format_phone(lead.phone2))
        end

      end

      describe "without any phone number" do
        it "returns nil" do
          lead.phone1 = nil
          lead.phone1_type = nil
          lead.phone2 = nil
          lead.phone2_type = nil
          expect(lead.message_sms_destination).to be_nil
        end
      end

    end

    it "returns the message_recipientid based on message_type" do
      lead.phone1 = "555-555-5511"
      lead.phone2 = "555-555-5512"
      lead.phone1_type = 'Home'
      lead.phone2_type = 'Cell'
      sms_message_type = create(:sms_message_type)
      email_message_type = create(:email_message_type)
      expect(lead.message_recipientid(message_type: sms_message_type)).to eq(Message.format_phone(lead.phone2))
      expect(lead.message_recipientid(message_type: email_message_type)).to eq(lead.email)
    end

    it "returns supported message types depending on data present" do
      sms_message_type
      email_message_type
      lead.phone1_type = 'Cell'
      expect(lead.message_types_available).to eq([sms_message_type, email_message_type])
      lead.email = nil
      expect(lead.message_types_available).to eq([sms_message_type])
    end

    it "returns whether the Lead has opted out of messaging" do
      refute(lead.optout?)
      lead.preference.optout_email = true
      lead.preference.save
      lead.reload
      assert(lead.optout?)
    end

    it "sets the optout flag" do
      refute(lead.optout?)
      lead.optout!
      assert(lead.optout?)
    end
  end
end
