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

      lead.scheduled_actions.update_all(state: 'rejected')
      lead.reload
      lead.trigger_event(event_name: 'claim', user: agent)
      lead.reload
      policy = EngagementPolicy.for_state('prospect').without_property.last
      scheduled_actions = lead.scheduled_actions

      #scheduled_actions = scheduler.create_scheduled_actions(lead: lead)
      expect(scheduled_actions.pending.size).to eq(policy.actions.count)

      scheduled_action = scheduled_actions.first
      schedule = scheduled_action.schedule
      compliance = scheduled_action.engagement_policy_action_compliance
      assert compliance.is_a?(EngagementPolicyActionCompliance)
      expect(compliance.expires_at.hour).to eq(schedule.time.hour)
      expect(compliance.expires_at.min).to eq(schedule.time.min)
      expect(compliance.expires_at.to_date).to eq(schedule.date)
    end

    #it "should reassign ScheduledActions to a new agent" do
      #seed_engagement_policy
      #lead = create(:lead, state: initial_state )
      #lead.reload
      #lead.trigger_event(event_name: 'claim', user: agent)
      #lead.reload

      #scheduled_actions = lead.scheduled_actions
      #action = scheduled_actions.first
      #compliance = action.engagement_policy_action_compliance
      #expect(action.user).to eq(agent)
      #expect(compliance.user).to eq(agent)

      #scheduler.reassign_lead_agent(lead: lead, agent: agent2)
      #lead.reload
      #scheduled_actions = lead.scheduled_actions
      #action = scheduled_actions.first
      #compliance = action.engagement_policy_action_compliance
      #expect(action.user).to eq(agent2)
      #expect(compliance.user).to eq(agent2)
    #end

    #it "should reassign ScheduledActions if the Lead agent is changed" do
      #seed_engagement_policy
      #lead = create(:lead, state: initial_state )
      #lead.reload
      #lead.trigger_event(event_name: 'claim', user: agent)
      #lead.reload

      #scheduled_actions = lead.scheduled_actions
      #action = scheduled_actions.first
      #compliance = action.engagement_policy_action_compliance
      #expect(action.user).to eq(agent)
      #expect(compliance.user).to eq(agent)

      #lead.user = agent2
      #lead.save
      #lead.reload

      #scheduled_actions = lead.scheduled_actions
      #action = scheduled_actions.first
      #compliance = action.engagement_policy_action_compliance
      #expect(action.user).to eq(agent2)
      #expect(compliance.user).to eq(agent2)

    #end
    
    describe "when completed with retry" do

      it "should create retries for ScheduledActions" do
        seed_engagement_policy
        lead = create(:lead, state: initial_state )
        lead.reload
        lead.trigger_event(event_name: 'claim', user: agent)
        lead.reload
        scheduled_actions = lead.scheduled_actions.order("created_at ASC")

        initial_scheduled_actions_count = ScheduledAction.count

        # First attempt
        original_action = scheduled_actions.last
        retry_count = original_action.engagement_policy_action.retry_count
        note_count = Note.count
        original_action.trigger_event(event_name: 'retry')
        original_action.reload
        new_actions = ScheduledAction.where(originator_id: original_action.id)
        expect(Note.count).to eq(note_count + 1)
        expect(original_action.engagement_policy_action.retry_count).to eq(retry_count)
        expect(new_actions.count).to eq(1)
        expect(ScheduledAction.count).to eq(initial_scheduled_actions_count + 1)

        new_action = nil

        # Subsequent Attempts
        retry_count.times do |retry_number|
          new_action = new_actions.first
          note_count = Note.count
          expect(new_action.engagement_policy_action_compliance.present?)
          expect(new_action.attempt).to eq(retry_number + 2)
          new_action.trigger_event(event_name: 'retry')
          expect(Note.count).to eq(note_count + 1)
          new_action.reload
          expect(new_action.state).to eq('completed_retry')
          new_actions = ScheduledAction.where(originator_id: new_action.id)
          if retry_number == (retry_count - 1)
            expect(new_actions.count).to eq(0)
            expect(ScheduledAction.count).to eq(initial_scheduled_actions_count + retry_number + 1)
          else
            expect(new_actions.count).to eq(1)
            expect(ScheduledAction.count).to eq(initial_scheduled_actions_count + retry_number + 2)
          end
        end

        # There shouldn't be any new retry records after attempt limit is reached
        expect(new_action.state).to eq('completed_retry')
        expect(new_action.engagement_policy_action_compliance.present?)
        expect(new_actions.count).to eq(0)
        expect(ScheduledAction.count).to eq(initial_scheduled_actions_count + 4)
      end

      it "should assign the retry record to the lead owner if the lead owner completed the task" do
        seed_engagement_policy
        lead = create(:lead, state: initial_state )
        lead.reload
        lead.trigger_event(event_name: 'claim', user: agent)
        lead.reload
        scheduled_actions = lead.scheduled_actions.order("created_at ASC")
        original_action = scheduled_actions.last
        original_action.trigger_event(event_name: 'retry', user: lead.user)
        lead.reload
        retry_action = lead.scheduled_actions.order(created_at: :desc).first
        expect(retry_action.user).to eq(lead.user)
      end


      it "should assign the retry record to the lead owner if another agent completed the task" do
        seed_engagement_policy
        lead = create(:lead, state: initial_state )
        lead.reload
        assert(agent2 != lead.user)
        lead.trigger_event(event_name: 'claim', user: agent)
        lead.reload
        scheduled_actions = lead.scheduled_actions.order("created_at ASC")
        original_action = scheduled_actions.last
        original_action.trigger_event(event_name: 'retry', user: agent2)
        lead.reload
        retry_action = lead.scheduled_actions.order(created_at: :desc).first
        expect(retry_action.user).to eq(lead.user)
      end


    end


    it "should create retries for a Personal Task without an associated Reason" do
      scheduled_action = ScheduledAction.new(
        user: agent,
        target: agent,
        description: "This is a test"
      )

      scheduled_action.save!

      scheduled_action_count = ScheduledAction.count

      expect(ScheduledAction.count).to eq(1)
      scheduled_action.trigger_event(event_name: 'retry')
      expect(ScheduledAction.count).to eq(2)

    end

    it "should create a retry with a provided delay value and unit" do
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
      original_action.completion_retry_delay_value = 10
      original_action.completion_retry_delay_unit = 'days'
      original_action.trigger_event(event_name: 'retry')
      original_action.reload
      new_actions = ScheduledAction.where(originator_id: original_action.id)
      expect(new_actions.count).to eq(1)
      expect(new_actions.first.schedule.to_datetime.day).to eq(( DateTime.now + 10.days ).day)

    end

    describe "creating a message reply task for the message's associated Lead" do
      include_context "messaging"

      let(:lead) { create(:lead) }
      let(:message) { create(:message,
                              messageable: lead,
                              message_type: email_message_type,
                              user_id: agent.id,
                              state: 'sent',
                              senderid: lead.email,
                              recipientid: 'incoming@example.com',
                              delivered_at: DateTime.now
                            )}

      it "given a Message record it should create a message reply task assigned to the associated Lead" do
        lead.trigger_event(event_name: 'claim', user: agent)
        lead.reload
        message
        task = EngagementPolicyScheduler.new.create_lead_incoming_message_reply_task(message)
        expect(message.user).to eq(agent)
        expect(lead.scheduled_actions).to include(task)
        expect(task.lead_action.name).to eq('Send Email')
        expect(task.reason.name).to eq('Message Response')
        expect(task.engagement_policy_action.description).to eq('Require response to incoming message')
        expect(task.engagement_policy_action.deadline).to eq(2.0)
        expect(task.engagement_policy_action_compliance.expires_at).to eq(message.delivered_at + 2.hours)
      end

      it "should award points to the agent if the task is completed" do
        initial_score = agent.score
        lead.trigger_event(event_name: 'claim', user: agent)
        lead.reload
        task = EngagementPolicyScheduler.new.create_lead_incoming_message_reply_task(message)
        task.trigger_event(event_name: 'complete', user: agent)
        agent.reload
        expect(agent.score).to eq(initial_score + 2)
      end
    end

  end


end
