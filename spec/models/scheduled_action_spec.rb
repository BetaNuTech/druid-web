# == Schema Information
#
# Table name: scheduled_actions
#
#  id                                     :uuid             not null, primary key
#  user_id                                :uuid
#  target_id                              :uuid
#  target_type                            :string
#  originator_id                          :uuid
#  lead_action_id                         :uuid
#  reason_id                              :uuid
#  engagement_policy_action_id            :uuid
#  engagement_policy_action_compliance_id :uuid
#  description                            :text
#  completed_at                           :datetime
#  state                                  :string           default("pending")
#  attempt                                :integer          default(1)
#  created_at                             :datetime         not null
#  updated_at                             :datetime         not null
#  remoteid                               :string
#  article_id                             :uuid
#  article_type                           :string
#  notify                                 :boolean          default(FALSE)
#  notified_at                            :datetime
#  notification_message                   :text
#

require 'rails_helper'

RSpec.describe ScheduledAction, type: :model do
  include_context "team_members"
  include_context "engagement_policy"
  include_context "messaging"

  describe "scheduling" do
    include_context "scheduled_actions"
    it "returns conflicting ScheduledActions, if any" do
      expect(scheduled_action1.conflicting.any?).to be(false)
      conflicting_action
      expect(scheduled_action1.conflicting.to_a).to eq([ conflicting_action ])
      expect(scheduled_action1.conflicting.any?).to be(true)
      expect(scheduled_action1.conflicting.count).to eq(1)
      conflicting_action.destroy
      expect(scheduled_action1.conflicting.any?).to be(false)
    end

    it "handles ScheduledActions with a Schedule having no duration" do
      scheduled_action1.schedule.duration = nil
      scheduled_action1.schedule.save
      expect(scheduled_action1.conflicting.any?).to be(false)
    end

    it "handles ScheduledActions with a Schedule with no end_time" do
      schedule = Schedule.new(date: Date.current, time: DateTime.current, duration: 30, end_time: nil)
      scheduled_action1.schedule = schedule
      refute(scheduled_action1.conflicting.any?)
    end

  end

  describe "completion" do

    describe "by owner" do
      let(:lead) { create(:lead, state: 'open') }
      before do
        seed_engagement_policy
        lead
      end

      it "should allow the owner agent to complete a task" do
        lead.trigger_event(event_name: 'claim', user: team1_agent1)
        lead.reload
        scheduled_action = lead.scheduled_actions.last
        expect(scheduled_action.user).to eq(team1_agent1)
        scheduled_action.trigger_event(event_name: 'complete', user: team1_agent1)
        scheduled_action.reload
        expect(scheduled_action.state).to eq('completed')
        expect(scheduled_action.user).to eq(team1_agent1)
      end

    end

    describe "by other agent" do
      before do
        seed_engagement_policy
      end

      it "should allow an agent to complete a task assigned to another agent in the same team" do
        lead = create(:lead, state: 'open')
        lead.trigger_event(event_name: 'claim', user: team1_agent1)
        lead.reload
        scheduled_action = lead.scheduled_actions.pending.last
        expect(scheduled_action.state).to eq('pending')
        expect(scheduled_action.user).to eq(team1_agent1)
        scheduled_action.trigger_event(event_name: 'complete', user: team1_agent2)
        scheduled_action.reload
        expect(scheduled_action.state).to eq('completed')
        expect(scheduled_action.user).to eq(team1_agent2)
      end

      #it "should disallow an agent to complete a task assigned to another agent in a different team" do
        #lead.trigger_event(event_name: 'claim', user: team1_agent1)
        #lead.reload
        #scheduled_action = lead.scheduled_actions.first
        #expect(scheduled_action.user).to eq(team1_agent1)
        #scheduled_action.trigger_event(event_name: 'complete', user: team2_agent1)
        #scheduled_action.reload
        #expect(scheduled_action.user).to_not eq(team2_agent1)
        #expect(scheduled_action.state).to eq('pending')
      #end

    end

    describe "contact event" do
      include_context "scheduled_actions"
      let(:lead) {
        lead = create(:lead, state: 'open')
        lead.first_comm = 1.hour.ago
        lead.trigger_event(event_name: 'claim', user: team1_agent1)
        lead.reload
        lead
      }
      let(:lead_action_contact) { create(:lead_action, is_contact: true) }
      let(:lead_action_no_contact) { create(:lead_action, is_contact: false) }
      let(:scheduled_action_contact) {
        scheduled_action1.lead_action = lead_action_contact
        scheduled_action1.target = lead
        scheduled_action1.save!
        scheduled_action1
      }
      let(:scheduled_action_no_contact) {
        scheduled_action2.lead_action = lead_action_no_contact
        scheduled_action2.target = lead
        scheduled_action2.save!
        scheduled_action2
      }
      it 'should not create a contact event upon completion if is it not a contact action' do
        event_count = lead.contact_events.count
        full_count = ContactEvent.count
        scheduled_action_no_contact.trigger_event(event_name: :complete, user: user)
        lead.reload
        expect(lead.contact_events.count).to eq(event_count)
        expect(ContactEvent.count).to eq(full_count)
        scheduled_action_contact.trigger_event(event_name: :complete, user: user)
        lead.reload
        expect(lead.contact_events.count).to eq(event_count + 1)
        expect(ContactEvent.count).to eq(full_count + 1)
        event = lead.contact_events.last
        expect(event.article).to eq(scheduled_action_contact)
        expect(event.lead_time).to eq(1)
        expect(event.user).to eq(lead.user)
        expect(event.lead).to eq(lead)
      end
    end

  end

  describe "notifications" do
    include_context "scheduled_actions"

    let(:notification_action) { create(:lead_action, notify: true) }

    before do
      scheduled_action1.lead_action = notification_action
      scheduled_action1.notify = true
      scheduled_action1.notification_message = "Notification message"
      scheduled_action1.save!
    end

    it "should report if its lead action wants notification" do
      assert(scheduled_action1.wants_notification?)

      scheduled_action1.notify = false
      scheduled_action1.lead_action = nil
      refute(scheduled_action1.wants_notification?)

      scheduled_action1.notify = true
      scheduled_action1.lead_action = nil
      assert(scheduled_action1.wants_notification?)

      scheduled_action1.notify = false
      scheduled_action1.lead_action = notification_action
      assert(scheduled_action1.wants_notification?)
    end

    it "validates the presence of notification_message if notify is true" do
      assert(scheduled_action1.notify)
      assert(scheduled_action1.valid?)
      scheduled_action1.notification_message = nil
      refute(scheduled_action1.valid?)
    end
  end

  describe "system user for notifications" do
    let(:system_user) { 
      user = User.find_by(email: 'system@bluesky.internal')
      if user.nil?
        user = User.create!(
          email: 'system@bluesky.internal',
          password: SecureRandom.hex(32),
          role: Role.find_or_create_by!(name: 'Administrator', slug: 'administrator'),
          confirmed_at: Time.current,
          system_user: true
        )
        user.create_profile!(first_name: 'Bluesky')
      end
      user
    }
    let(:lead) { create(:lead, phone1: '555-555-5555', phone1_type: 'Cell') }
    let(:notification_action) { create(:lead_action, notify: true) }
    let(:scheduled_action) { create(:scheduled_action, 
      target: lead, 
      lead_action: notification_action,
      notification_message: "Test notification",
      notify: true
    ) }

    before do
      system_user # ensure system user exists
      lead.preference.update!(optin_sms: true, optin_email: true)
    end

    describe "#send_notification" do
      it "uses system user as sender for appointment reminder messages" do
        allow(lead).to receive(:message_types_available).and_return([MessageType.email])
        
        expect(Message).to receive(:new_message).with(
          hash_including(
            from: system_user,
            to: lead,
            subject: 'Appointment Reminder',
            body: "Test notification"
          )
        ).and_return(double(save!: true, deliver!: true))
        
        scheduled_action.send_notification
      end

      it "sends notifications via SMS with system user" do
        allow(lead).to receive(:message_types_available).and_return([MessageType.sms])
        
        expect(Message).to receive(:new_message).with(
          hash_including(
            from: system_user,
            to: lead,
            message_type: MessageType.sms,
            subject: 'Appointment Reminder'
          )
        ).and_return(double(save!: true, deliver!: true))
        
        scheduled_action.send_notification
      end

      it "sends notifications via both email and SMS with system user" do
        allow(lead).to receive(:message_types_available).and_return([MessageType.email, MessageType.sms])
        
        # Expect both email and SMS messages
        expect(Message).to receive(:new_message).with(
          hash_including(from: system_user, message_type: MessageType.email)
        ).and_return(double(save!: true, deliver!: true))
        
        expect(Message).to receive(:new_message).with(
          hash_including(from: system_user, message_type: MessageType.sms)
        ).and_return(double(save!: true, deliver!: true))
        
        scheduled_action.send_notification
      end

      it "strips HTML from SMS notifications" do
        scheduled_action.notification_message = "<p>HTML notification</p>"
        allow(lead).to receive(:message_types_available).and_return([MessageType.sms])
        
        expect(Message).to receive(:new_message).with(
          hash_including(
            from: system_user,
            body: "HTML notification"
          )
        ).and_return(double(save!: true, deliver!: true))
        
        scheduled_action.send_notification
      end
    end
  end
end
