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

    it "should create retries for ScheduledActions" do
      seed_engagement_policy
      lead = create(:lead, state: initial_state )
      lead.reload
      lead.trigger_event(event_name: 'claim', user: agent)
      lead.reload
      scheduled_actions = lead.scheduled_actions.order("created_at ASC")

      retry_count = 2
      initial_scheduled_actions_count = ScheduledAction.count

      # First attempt
      original_action = scheduled_actions.last
      original_action.trigger_event(event_name: 'retry')
      original_action.reload
      new_actions = ScheduledAction.where(originator_id: original_action.id)
      expect(original_action.engagement_policy_action.retry_count).to eq(retry_count)
      expect(new_actions.count).to eq(1)
      expect(ScheduledAction.count).to eq(initial_scheduled_actions_count + 1)

      # First retry
      new_action = new_actions.first
      expect(new_action.engagement_policy_action_compliance.present?)
      expect(new_action.attempt).to eq(2)
      new_action.trigger_event(event_name: 'retry')
      new_action.reload
      expect(new_action.state).to eq('completed_retry')
      new_actions = ScheduledAction.where(originator_id: new_action.id)
      expect(new_actions.count).to eq(1)
      expect(ScheduledAction.count).to eq(initial_scheduled_actions_count + 2)

      # Second/Final retry
      new_action = new_actions.first
      expect(new_action.attempt).to eq(3)
      expect(new_action.engagement_policy_action_compliance.present?)
      new_action.trigger_event(event_name: 'retry')
      new_action.reload
      expect(new_action.state).to eq('completed_retry')
      new_actions = ScheduledAction.where(originator_id: new_action.id)

      # There shouldn't be any new retry records
      expect(new_action.state).to eq('completed_retry')
      expect(new_action.engagement_policy_action_compliance.present?)
      expect(new_actions.count).to eq(0)
      expect(ScheduledAction.count).to eq(initial_scheduled_actions_count + 2)

    end

    it "should create retries for a Personal Task without an associated Reason" do
      scheduled_action = ScheduledAction.new(
        user: agent,
        description: "This is a test"
      )

      scheduled_action.save!

      scheduled_action_count = ScheduledAction.count

      scheduled_action.trigger_event(event_name: 'retry')
      expect(ScheduledAction.count).to eq(2)

    end

  end


end
