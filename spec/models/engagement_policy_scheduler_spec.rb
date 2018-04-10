require 'rails_helper'

RSpec.describe EngagementPolicyScheduler do
  include_context "engagement_policy"

  before(:each) do
    seed_engagement_policy
  end

  describe "creating ScheduledActions" do

    let(:scheduler) {  EngagementPolicyScheduler.new }
    let(:initial_state) { 'open' }

    it "should create ScheduledActions for the Lead based on Policy" do
      seed_engagement_policy
      lead = create(:lead, state: initial_state )
      expect(ScheduledAction.count).to eq(0)

      policy = EngagementPolicy.for_state(initial_state).without_property.last
      scheduled_actions = scheduler.create_scheduled_actions(lead: lead)
      expect(scheduled_actions.size).to eq(policy.actions.count)
    end

  end


end
