require 'rails_helper'

RSpec.describe EngagementPolicyScheduler do
  include_context "engagement_policy"
  include_context "users"

  before(:each) do
    seed_engagement_policy
  end

  describe "creating ScheduledActions" do

    let(:scheduler) {  EngagementPolicyScheduler.new }
    let(:initial_state) { 'open' }
    let(:secondary_state) { 'claimed' }

    it "should create ScheduledActions for the Lead based on Policy" do
      seed_engagement_policy
      lead = create(:lead, state: initial_state )
      lead.reload

      policy = EngagementPolicy.for_state(initial_state).without_property.last
      scheduled_actions = lead.scheduled_actions

      #scheduled_actions = scheduler.create_scheduled_actions(lead: lead)
      expect(scheduled_actions.size).to eq(policy.actions.count)

      scheduled_action = scheduled_actions.first
      schedule = scheduled_action.schedule
      compliance = scheduled_action.engagement_policy_action_compliance
      assert compliance.is_a?(EngagementPolicyActionCompliance)
      expect(compliance.expires_at.hour).to eq(schedule.time.hour)
      expect(compliance.expires_at.min).to eq(schedule.time.min)
      expect(compliance.expires_at.to_date).to eq(schedule.date)

      lead.scheduled_actions.destroy_all
      lead.reload
      lead.trigger_event(event_name: 'claim', user: agent)
      lead.reload
      policy = EngagementPolicy.for_state('prospect').without_property.last
      scheduled_actions = lead.scheduled_actions

      #scheduled_actions = scheduler.create_scheduled_actions(lead: lead)
      expect(scheduled_actions.size).to eq(policy.actions.count)

      scheduled_action = scheduled_actions.first
      schedule = scheduled_action.schedule
      compliance = scheduled_action.engagement_policy_action_compliance
      assert compliance.is_a?(EngagementPolicyActionCompliance)
      expect(compliance.expires_at.hour).to eq(schedule.time.hour)
      expect(compliance.expires_at.min).to eq(schedule.time.min)
      expect(compliance.expires_at.to_date).to eq(schedule.date)
    end

    it "should reassign ScheduledActions to a new agent" do
      seed_engagement_policy
      lead = create(:lead, state: initial_state )
      lead.reload
      lead.trigger_event(event_name: 'claim', user: agent)
      lead.reload

      scheduled_actions = lead.scheduled_actions
      action = scheduled_actions.first
      compliance = action.engagement_policy_action_compliance
      expect(action.user).to eq(agent)
      expect(compliance.user).to eq(agent)

      scheduler.reassign_lead_agent(lead: lead, agent: agent2)
      lead.reload
      scheduled_actions = lead.scheduled_actions
      action = scheduled_actions.first
      compliance = action.engagement_policy_action_compliance
      expect(action.user).to eq(agent2)
      expect(compliance.user).to eq(agent2)
    end

    it "should reassign ScheduledActions if the Lead agent is changed" do
      seed_engagement_policy
      lead = create(:lead, state: initial_state )
      lead.reload
      lead.trigger_event(event_name: 'claim', user: agent)
      lead.reload

      scheduled_actions = lead.scheduled_actions
      action = scheduled_actions.first
      compliance = action.engagement_policy_action_compliance
      expect(action.user).to eq(agent)
      expect(compliance.user).to eq(agent)

      lead.user = agent2
      lead.save
      lead.reload

      scheduled_actions = lead.scheduled_actions
      action = scheduled_actions.first
      compliance = action.engagement_policy_action_compliance
      expect(action.user).to eq(agent2)
      expect(compliance.user).to eq(agent2)

    end

  end


end
