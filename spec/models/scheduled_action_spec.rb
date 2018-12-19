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
#

require 'rails_helper'

RSpec.describe ScheduledAction, type: :model do
  include_context "team_members"
  include_context "engagement_policy"

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
end
