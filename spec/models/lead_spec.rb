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
#  phone1_type         :string           default("Cell")
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
  include_context "messaging"
  include_context "team_members"

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
      expect(lead.permitted_state_events.sort).to eq([:claim, :disqualify, :postpone, :abandon].sort)
      lead.claim!
      expect(lead.state).to eq('prospect')
      expect(lead.permitted_state_events.sort).to eq([:abandon, :apply, :approve, :disqualify, :postpone, :release, :show].sort)
      lead.disqualify!
      expect(lead.permitted_state_events).to eq([:requalify])
    end

    it "lists valid states" do
      expect(lead.permitted_states.sort).to eq([:prospect, :disqualified, :abandoned, :future].sort)
      lead.claim!
      expect(lead.state).to eq('prospect')
      expect(lead.permitted_states.sort).to eq([:abandoned, :application, :approved, :disqualified, :future, :open, :showing].sort)
    end

    it "lists 'active' leads" do
      expect(Lead.active).to eq([lead])
    end

    describe "lead_transitions" do
      let(:memo) { 'Lead transition memo 1' }
      let(:lead) { create(:lead, state: 'open', user: agent, property: agent.property) }
      let(:unit_type) { create(:unit_type, property: lead.property) }

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
        assert(lead.scheduled_actions.pending.count > 0)
        expect(lead.user).to eq(agent)
        lead.postpone!
        lead.reload
        expect(lead.scheduled_actions.pending.count).to eq(0)
        expect(lead.user).to be_nil
        expect(lead.priority).to eq('low')
      end

      it "cleans up record tasks and agent association upon 'disqualify'" do
        seed_engagement_policy
        lead.trigger_event(event_name: 'claim', user: agent)
        lead.reload
        assert(lead.scheduled_actions.pending.count > 0)
        expect(lead.user).to eq(agent)
        lead.disqualify!
        lead.reload
        expect(lead.scheduled_actions.pending.count).to eq(0)
        expect(lead.user).to eq(agent)
        expect(lead.priority).to eq('zero')
      end

      it "allows transition to waitlist if unit preference is set" do
        seed_engagement_policy
        lead.state = 'prospect'
        lead.save!
        expect(lead.state).to eq('prospect')
        expect(lead.permitted_state_events).to_not include(:wait_for_unit)
        lead.preference.unit_type = unit_type
        lead.preference.save!
        lead.reload
        expect(lead.permitted_state_events).to include(:wait_for_unit)
        lead.trigger_event(event_name: 'wait_for_unit', user: agent)
        lead.reload
        expect(lead.state).to eq('waitlist')
        expect(lead.permitted_state_events).to_not include(:revisit_unit_available)
      end

      it "allows transition from waitlist to open if units are available to lease" do
        seed_engagement_policy
        unit_type = create(:unit_type, property: lead.property)
        lead.preference.unit_type = unit_type
        lead.state = 'waitlist'
        lead.save!
        expect(lead.permitted_state_events).to_not include(:revisit_unit_available)
        unit = create(:unit, unit_type: unit_type, property: lead.property, lease_status: 'available')
        expect(lead.permitted_state_events).to include(:revisit_unit_available)
        lead.trigger_event(event_name: 'revisit_unit_available')
        lead.reload
        expect(lead.state).to eq('open')
      end

      it "allows transition from waitlist to open if no unit preference is set" do
        seed_engagement_policy
        unit_type = create(:unit_type, property: lead.property)
        lead.preference.unit_type = nil
        lead.preference.save!
        lead.state = 'waitlist'
        lead.save!
        expect(lead.permitted_state_events).to include(:revisit_unit_available)
        lead.trigger_event(event_name: 'revisit_unit_available')
        lead.reload
        expect(lead.state).to eq('open')
      end

      describe "sms opt-in" do
        include_context "message_templates"

        before do
          seed_engagement_policy
        end

        it "sends an sms opt-in message upon claiming" do
          lead.preference.optin_sms = false
          lead.preference.optin_sms_date = nil
          lead.preference.save!
          lead.phone1 = '5555555555'
          lead.phone1_type = 'Cell'
          lead.property = agent.property
          lead.save!
          expect(lead.messages.for_compliance.count).to eq(1)
          lead.trigger_event(event_name: 'claim', user: agent)
          lead.reload
          expect(lead.messages.for_compliance.count).to eq(1)
        end
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
        lead.state = "approved"
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
        expect(lead.scheduled_actions.pending.count).to be > 0
        lead.abandon!
        lead.reload
        expect(lead.scheduled_actions.pending.count).to eq(0)
      end

      it "should clear all old tasks when disqualified" do
        ScheduledAction.destroy_all
        agent = team1_agent1
        property = agent.properties.first
        lead.property = property
        lead.trigger_event(event_name: 'claim', user: agent)
        lead.reload
        expect(lead.scheduled_actions.pending.count).to be > 0
        lead.disqualify!
        lead.reload
        expect(lead.scheduled_actions.pending.count).to eq(0)
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
        lead.state = 'approved'
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
    let(:lead) { create(:lead, preference: create(:lead_preference)) }
    let(:sms_message_type) {create(:sms_message_type)}
    let(:email_message_type) {create(:email_message_type)}

    it "returns message_template information" do
      expected_data_keys = %w{ lead_name lead_title lead_first_name
                              lead_last_name lead_floorplan agent_name agent_title property_name
                              property_address property_address_html property_city property_amenities
                              property_website property_phone property_school_district
                              property_application_url html_email_header_image email_bluestone_logo
                              email_housing_logo agent_first_name agent_last_name
                              email_unsubscribe_link }
     attrs = lead.message_template_data
     assert attrs.is_a?(Hash)
     expect(attrs.keys.sort).to eq(expected_data_keys.sort)
    end

    it "returns the preferred message_email_destination" do
      expect(lead.message_email_destination).to eq(lead.email)
    end

    describe "is reclaimed from upon reciept of a message" do
      describe "when disqualified" do
        it "is assigned to the previously assigned agent if there was one" do
          lead.state = 'prospect'
          lead.user = agent
          lead.save
          lead.disqualify!
          lead.reload
          lead
          lead.requalify_if_disqualified
          lead.reload
          expect(lead.user).to eq(agent)
          expect(lead.state).to eq('prospect')
        end
      end
      describe "when abandoned" do
        it "is assigned to the previously assigned agent if there was one" do
          lead.state = 'prospect'
          lead.user = agent
          lead.save
          lead.abandon!
          lead.reload
          lead
          lead.requalify_if_disqualified
          lead.reload
          expect(lead.user).to eq(agent)
          expect(lead.state).to eq('prospect')
        end
      end
    end

    describe "requesting sms communication authorization" do
      let(:lead) { create(:lead, state: 'open',  preference: create(:lead_preference, { optin_sms: false, optin_sms_date: nil })) }
      let(:lead2) { create(:lead, state: 'open',  preference: create(:lead_preference, { optin_sms: false, optin_sms_date: nil })) }
      let(:lead3) { create(:lead, state: 'open',  preference: create(:lead_preference, { optin_sms: false, optin_sms_date: nil })) }
      describe "when there are no duplicates" do
        describe 'when the lead has not responded to an authorization request' do
          it "should send the sms optin request" do
            lead; lead2; lead3
            lead.trigger_event(event_name: :claim, user: agent)
            lead2.trigger_event(event_name: :claim, user: agent)
            lead3.trigger_event(event_name: :claim, user: agent)
            expect(lead3.comments.count).to eq(4)
          end
        end
        describe 'when the lead has responded affirmatively to an authorization request' do
          it "should not send the sms optin request" do
            lead; lead2; lead3
            lead.preference.optin_sms = true
            lead.preference.optin_sms_date = Time.now
            lead.preference.save!
            lead.trigger_event(event_name: :claim, user: agent)
            lead2.trigger_event(event_name: :claim, user: agent)
            lead3.trigger_event(event_name: :claim, user: agent)
            expect(lead3.comments.count).to eq(4)
          end
        end
        describe 'when the lead has responded negatively to an authorization request' do
          it "should not send the sms optin request" do
            lead; lead2; lead3
            lead.preference.optin_sms = false
            lead.preference.optin_sms_date = Time.now
            lead.preference.save!
            lead.trigger_event(event_name: :claim, user: agent)
            lead2.trigger_event(event_name: :claim, user: agent)
            lead3.trigger_event(event_name: :claim, user: agent)
            expect(lead3.comments.count).to eq(4)
          end
        end
      end
      describe "when there are duplicates with matching phone numbers" do
        let(:phone) { '5555557777' }
        before do
          lead.phone1 = phone; lead.save
          lead2.phone1 = phone; lead2.save
          lead3.phone1 = phone; lead3.save
        end
        describe "when there are only open duplicates" do
          it "should send the sms optin request" do
            lead3.trigger_event(event_name: :claim, user: agent)
            expect(lead3.comments.count).to eq(5)
          end
        end
        describe "when there is a non-open duplicate that did not authorize sms" do
          it "should not send the sms optin request" do
            lead.preference.optin_sms = false
            lead.preference.save!
            lead.state = 'prospect'
            lead.save!
            lead3.trigger_event(event_name: :claim, user: agent)
            expect(lead3.comments.count).to eq(4)
          end
        end
        describe "when a phone duplicate has authorized sms" do
          it "should not send the sms optin request" do
            lead.preference.optin_sms = true
            lead.preference.save!
            lead.state = 'prospect'
            lead.save!
            lead3.trigger_event(event_name: :claim, user: agent)
            expect(lead3.comments.count).to eq(4)
          end
          it "should automatically approve sms communication" do
            lead.preference.optin_sms = true
            lead.preference.optin_sms_date = 1.day.ago
            lead.preference.save!
            lead.state = 'prospect'
            lead.save!
            lead3.trigger_event(event_name: :claim, user: agent)
            lead3.reload
            expect(lead3.preference.optin_sms).to be true
          end
        end
      end
    end

    describe "new lead messaging" do
      it "is not sent if the lead is stale" do
        lead = create(:lead, state: 'open')
        assert(lead.send_new_lead_messaging)
        lead2 = create(:lead, state: 'open')
        lead2.created_at = 7.days.ago
        lead2.save!
        refute(lead2.send_new_lead_messaging)
        assert(lead2.comments.map(&:content).any?{|c| c.match?(/skipped/)})
      end
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
        it 'returns the second phone number if the first phone number is not present' do
          lead.phone1 = ' '
          lead.phone2 = '555-555-5512'
          lead.phone1_type = 'Cell'
          lead.phone2_type = 'Cell'
          expect(lead.message_sms_destination).to eq(Message.format_phone(lead.phone2))
          lead.phone1_type = 'Home'
          lead.phone2_type = 'Home'
          expect(lead.message_sms_destination).to eq(nil)
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
      lead.save
      lead.preference.optout_email = false
      lead.preference.optin_sms = true
      lead.preference.save
      sms_message_type = MessageType.sms || create(:sms_message_type)
      email_message_type = MessageType.email || create(:email_message_type)
      expect(lead.message_recipientid(message_type: sms_message_type)).to eq(Message.format_phone(lead.phone2))
      expect(lead.message_recipientid(message_type: email_message_type)).to eq(lead.email)
    end

    it "returns supported message types depending on data present" do
      ENV[MessageType::SMS_MESSAGING_DISABLED_FLAG] = 'false'
      sms_message_type = MessageType.sms || create(:sms_message_type)
      email_message_type = MessageType.email || create(:email_message_type)
      lead.phone1_type = 'Cell'
      lead.save
      lead.reload
      expect(lead.message_types_available.sort).to eq([sms_message_type,email_message_type].sort)
      lead.phone1 = lead.phone2 = nil
      lead.save!
      expect(lead.message_types_available).to eq([email_message_type])
    end

    it "returns whether the Lead has opted out of messaging" do
      refute(lead.optout_email?)
      lead.preference.optout_email = true
      lead.preference.save
      lead.reload
      assert(lead.optout_email?)
    end

    it "sets the optout flag" do
      refute(lead.optout_email?)
      lead.optout_email!
      assert(lead.optout_email?)
    end

    describe "handling message delivery" do
      before(:each) do
        ENV[MessageType::SMS_MESSAGING_DISABLED_FLAG] = 'true'
      end

      let(:lead) { create(:lead, user: agent, property: agent.property) }
      let(:outgoing_email_message) {
        message = Message.new_message(
          from: agent, to: lead, message_type: email_message_type,
          subject: 'Test EMAIL Message1', body: 'This is a test EMAIL message')
        message.save!; message }
      let(:outgoing_sms_message) {
        message = Message.new_message(
          from: agent, to: lead, message_type: sms_message_type,
          subject: 'Test SMS Message1', body: 'This is a test SMS message')
        message.save!; message }
      let(:incoming_email_message) {
        message = Message.create!(
          messageable: lead,
          user: agent,
          state: 'sent',
          senderid: lead.email,
          recipientid: 'incomingemailaddress@example.com',
          subject: 'Test Incoming EMAIL Message1',
          body: 'Test incoming EMAIL message',
          delivered_at: DateTime.now,
          message_type: email_message_type,
          incoming: true
        )
        delivery = MessageDelivery.create(
          message: message,
          message_type: message.message_type,
          attempt: 1,
          attempted_at: message.delivered_at,
          status: "OK",
          delivered_at: message.delivered_at
        )
        message.handle_message_delivery(delivery)
        message.reload
        message
      }

      let(:incoming_sms_message) {
        message = Message.create!(
          messageable: lead,
          user: agent,
          state: 'sent',
          senderid: lead.phone1,
          recipientid: 'incomingsms',
          subject: 'Test Incoming SMS Message1',
          body: 'Test incoming SMS message',
          delivered_at: DateTime.now,
          message_type: sms_message_type,
          incoming: true
        )
        delivery = MessageDelivery.create(
          message: message,
          message_type: message.message_type,
          attempt: 1,
          attempted_at: message.delivered_at,
          status: "OK",
          delivered_at: message.delivered_at
        )
        message.handle_message_delivery(delivery)
        message.reload
        message
      }

      it "should update last_contact upon delivery of an email message" do
        last_contact = lead.last_comm
        outgoing_email_message.deliver!
        lead.reload
        outgoing_email_message.reload
        expect(lead.last_comm).to_not eq(last_contact)
        expect(lead.last_comm).to eq(outgoing_email_message.delivered_at)
      end

      it "should update last_contact upon delivery of an sms message" do
        ENV[MessageType::SMS_MESSAGING_DISABLED_FLAG] = 'false'
        last_contact = lead.last_comm
        outgoing_sms_message.deliver!
        lead.reload
        expect(lead.last_comm).to_not eq(last_contact)
        expect(lead.last_comm.to_i).to eq(outgoing_sms_message.delivered_at.to_i)
      end

      it "should not update last_contact upon receipt of an email message" do
        last_contact = lead.last_comm
        incoming_email_message
        lead.reload
        expect(lead.last_comm).to_not eq(last_contact)
        expect(lead.last_comm).to_not eq(incoming_email_message.delivered_at)
      end

      it "should not update last_contact upon receipt of an sms message" do
        last_contact = lead.last_comm
        incoming_sms_message
        lead.reload
        expect(lead.last_comm).to_not eq(last_contact)
        expect(lead.last_comm).to_not eq(incoming_sms_message.delivered_at)
      end

      describe "creating a reply task upon message receipt" do
        include_context "engagement_policy"

        it "should create a reply task for incoming messages" do
          seed_engagement_policy
          initial_task_count = lead.scheduled_actions.count
          assert(incoming_email_message.incoming?)
          lead.reload
          expect(lead.scheduled_actions.count).to eq(initial_task_count + 1)
        end

        it "should not create a reply task for outgoing messages" do
          seed_engagement_policy
          initial_task_count = lead.scheduled_actions.count
          refute(outgoing_email_message.incoming?)
          lead.reload
          expect(lead.scheduled_actions.count).to eq(initial_task_count)
        end

        it "should automatically complete a reply task upon delivery of an outgoing message" do
          seed_engagement_policy
          initial_task_count = lead.scheduled_actions.count
          incoming_email_message
          lead.reload
          expect(lead.scheduled_actions.count).to eq(initial_task_count + 1)
          pending_task_count = lead.scheduled_actions.pending.count
          outgoing_email_message.deliver
          lead.reload
          expect(lead.scheduled_actions.pending.count).to eq(pending_task_count - 1)
        end

      end

    end

    describe "transitioning to the application state" do
      let(:application_email_walkin) {
        MessageTemplate.create(
          name: Lead::APPLICATION_EMAIL_NAME_WALKIN,
          subject: 'Walkin Rental Application',
          body: 'Walkin Rental Application',
          message_type: email_message_type,
        )
      }
      let(:application_email_online) {
        MessageTemplate.create(
          name: Lead::APPLICATION_EMAIL_NAME_ONLINE,
          subject: 'Walkin Rental Application',
          body: 'Walkin Rental Application',
          message_type: email_message_type
        )
      }

      let(:email_lead_action) { create(:lead_action, name: Lead::APPLICATION_COMMENT_ACTION_NAME)}
      let(:email_lead_reason) { create(:reason, name: Lead::APPLICATION_COMMENT_REASON_NAME)}

      let(:lead) { create(:lead, user: agent, property: agent.property)}

      before(:each) do
        email_lead_action
        email_lead_reason
        application_email_walkin
        application_email_online
        lead.state = 'prospect'
        lead.save!
      end

      it "sends a rental application" do
        message_count = lead.messages.count
        comment_count = lead.comments.count
        lead.trigger_event(event_name: :apply, user: agent)
        lead.save!
        lead.reload
        latest_message = lead.messages.order(created_at: :desc).first
        first_comment = lead.comments.order(created_at: :asc).to_a[1]
        expect(lead.messages.count).to eq(message_count + 1)
        expect(latest_message).to eq(lead.messages.order(created_at: :desc).first)
        expect(latest_message.subject).to eq(application_email_online.subject)
        expect(lead.comments.count).to eq(comment_count + 3)
        #expect(first_comment.content).to eq("SENT: #{application_email_online.name}")
        assert(lead.comments.map(&:content).any?{|c| c.match?("SENT: #{application_email_online.name}")})
      end

      it "does not send a rental application if the template is missing" do
        template_name = application_email_online.name
        application_email_online.destroy
        application_email_walkin.destroy
        message_count = lead.messages.count
        comment_count = lead.comments.count
        lead.trigger_event(event_name: :apply, user: agent)
        lead.save!
        lead.reload
        latest_message = lead.messages.order(created_at: :desc).first
        first_comment = lead.comments.order(created_at: :asc).first
        expect(lead.messages.count).to eq(message_count)
        expect(lead.comments.count).to eq(comment_count + 2)
        expect(first_comment.content).to match("NOT SENT: #{template_name}")
        expect(first_comment.content).to match("Missing Message Template")
      end

      it "does not send a rental application of there is no agent" do
        template_name = application_email_online.name
        lead.user = nil
        lead.save!
        message_count = lead.messages.count
        comment_count = lead.comments.count
        lead.property.property_users.destroy_all
        lead.trigger_event(event_name: :apply, user: agent)
        lead.save!
        lead.reload
        latest_message = lead.messages.order(created_at: :desc).first
        expect(lead.messages.count).to eq(message_count)
        expect(lead.comments.count).to eq(comment_count + 2)
        assert(lead.comments.map(&:content).any?{|c| c.match? "NOT SENT: #{template_name}"})
        assert(lead.comments.map(&:content).any?{|c| c.match? "Lead has no agent"})
      end
    end

    describe "comments" do
      describe "contact comments" do
        let(:lead) {create(:lead)}
        let(:contact_lead_action) {create(:lead_action, is_contact: true)}
        let(:non_contact_lead_action) {create(:lead_action, is_contact: false)}
        let(:reason) { create(:reason)}
        let(:contact_note) {
          Note.create!(notable: lead, lead_action: contact_lead_action, reason: reason,
                      content: "Contact event")
        }
        let(:non_contact_note) {
          Note.create!(notable: lead, lead_action: non_contact_lead_action, reason: reason,
                      content: "Non-Contact event")
        }

        it "should update the Lead.last_comm when a contact comment is created" do
          lead
          last_contact = lead.last_comm
          non_contact_note
          lead.reload
          expect(lead.last_comm.to_i).to eq(last_contact.to_i)
          contact_note
          lead.reload
          expect(lead.last_comm).to_not eq(last_contact)
        end

      end
    end

  end

  describe "lead_referrals" do
    let(:property) { create(:property) }
    let(:lead) { build(:lead, property: property)}
    let(:resident) { create(:resident, property: property)}
    let(:lead_referral_source) { create(:lead_referral_source)}

    describe "inferring a lead_referral record" do
      before(:each) do
        LeadReferral.destroy_all
      end

      it "should create a record using a standard lead_referral_source" do
        lead.referral = lead_referral_source.name
        lead.save!
        lead.infer_referral_record
        lead.reload
        expect(lead.referrals.count).to eq(1)
        referral = lead.referrals.first
        expect(referral.referrable).to eq(lead_referral_source)
        expect(referral.note).to eq(lead_referral_source.name)
      end

      it "should create a record without an existing lead_referral_source" do
        lead.save!
        lead.infer_referral_record
        lead.reload
        expect(lead.referrals.count).to eq(1)
        referral = lead.referrals.first
        expect(referral.referrable).to be_nil
        expect(referral.note).to eq(lead.referral)
      end

      it "wont create a record if there are errors" do
        lead.referral = 'Test'
        lead.save!
        lead.errors.add(:base, 'test')
        assert lead.errors.any?
        lead.infer_referral_record
        lead.reload
        expect(lead.referrals.count).to eq(0)
      end

      it "wont create a record if there is no referral data" do
        lead.referral = nil
        lead.save!
        lead.infer_referral_record
        lead.reload
        expect(lead.referrals.count).to eq(0)
      end

      it "wont create a record if there are exising referrals" do
        lead.save!
        lead.infer_referral_record
        lead.reload
        expect(lead.referrals.count).to eq(1)
        lead.infer_referral_record
        lead.reload
        expect(lead.referrals.count).to eq(1)
      end
    end

    describe "future leads and followups" do
      it "should 'revisit' leads pending revisit" do
        lead.user = agent
        lead.state = 'future'
        lead.follow_up_at = Time.now + 1.day
        lead.property = agent.property
        lead.save!

        Lead.process_followups

        lead.reload
        expect(lead.state).to eq('future')

        lead.follow_up_at = 1.day.ago
        lead.save!

        Lead.process_followups

        lead.reload
        expect(lead.state).to eq('open')
      end

      it "should create a personal task for the associated agent" do
        user = agent
        lead.user = user
        lead.state = 'prospect'
        lead.property = agent.property
        lead.save!

        lead.follow_up_at = Time.now + 2.days
        lead.trigger_event(event_name: 'postpone', user: user)

        lead.reload
        user.reload
        tasks = user.scheduled_actions.order(created_at: :desc)

        task = tasks.last
        expect(lead.state).to eq('future')
        expect(task.description).to match(/Follow up on postponed lead/)
        expect(task.user).to eq(user)
        expect(task.target).to eq(user)
        expect(user.scheduled_actions).to include(task)
      end
    end
  end
end
