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
      schedule = Schedule.new(date: Date.today, time: Time.now, duration: 30, end_time: nil)
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
end
