require 'rails_helper'

RSpec.describe ScheduledActionPolicy do
  include_context 'team_members'
  include_context 'unroled_user'
  include_context "engagement_policy"

  describe 'scope' do
    it 'allows access to any admin' do
      scheduled_action = ScheduledAction.create(user: team1_agent1)
      scheduled_action2 = ScheduledAction.create(user: team2_agent1)
      collection = ScheduledActionPolicy::Scope.new(team1_manager1, ScheduledAction).resolve
      expect(collection.count).to eq(2)
      collection = ScheduledActionPolicy::Scope.new(team2_manager1, ScheduledAction).resolve
      expect(collection.count).to eq(2)
      collection = ScheduledActionPolicy::Scope.new(team2_corporate1, ScheduledAction).resolve
      expect(collection.count).to eq(2)
    end

    it 'allows access to owner' do
      scheduled_action = ScheduledAction.create(user: team1_agent1)
      scheduled_action2 = ScheduledAction.create(user: team2_agent1)
      collection = ScheduledActionPolicy::Scope.new(team1_agent1, ScheduledAction).resolve
      expect(collection.count).to eq(1)
      expect(collection.map(&:id).sort).to eq([scheduled_action.id])
      collection = ScheduledActionPolicy::Scope.new(team2_agent1, ScheduledAction).resolve
      expect(collection.count).to eq(1)
      expect(collection.map(&:id).sort).to eq([scheduled_action2.id])
    end

    it 'disallows access to agents belonging to other teams' do
      scheduled_action = ScheduledAction.create(user: team1_agent1)
      collection = ScheduledActionPolicy::Scope.new(team2_agent1, ScheduledAction).resolve
      expect(collection.count).to eq(0)
    end

    it 'allows access to agents within the same team' do
      scheduled_action = ScheduledAction.create(user: team1_agent1)
      collection = ScheduledActionPolicy::Scope.new(team1_agent2, ScheduledAction).resolve
      expect(collection.count).to eq(1)
    end
  end

  describe 'policy' do
    describe 'index?' do
      it 'should allow admin access' do
        assert(ScheduledActionPolicy.new(team1_manager1, ScheduledAction).index?)
      end

      it 'should allow agent access' do
        assert(ScheduledActionPolicy.new(team1_agent1, ScheduledAction).index?)
      end

      it 'should disallow non-user access' do
        refute(ScheduledActionPolicy.new(unroled_user, ScheduledAction).index?)
      end
    end

    describe 'show?' do
      it 'should allow admin access' do
        assert(ScheduledActionPolicy.new(team1_manager1, ScheduledAction).show?)
      end

      it 'should allow agent access' do
        assert(ScheduledActionPolicy.new(team1_agent1, ScheduledAction).show?)
      end

      it 'should disallow non-user access' do
        refute(ScheduledActionPolicy.new(unroled_user, ScheduledAction).show?)
      end
    end

    describe 'edit?' do
      let(:task_owner) { team1_agent1 }
      let(:lead) { create(:lead, user: task_owner, property: task_owner.team.properties.first)}

      describe 'a personal task' do
        let(:scheduled_action) { ScheduledAction.create(user: task_owner, target: task_owner )}

        it 'should allow admin access' do
          assert(ScheduledActionPolicy.new(team1_manager1, scheduled_action).edit?)
        end

        it 'should allow owner acces' do
          assert(ScheduledActionPolicy.new(task_owner, scheduled_action).edit?)
        end

        it 'should disallow nonowner access by same team' do
          refute(ScheduledActionPolicy.new(team1_agent2, scheduled_action).edit?)
        end

        it 'should disallow nonowner access outside of team' do
          refute(ScheduledActionPolicy.new(team2_agent1, scheduled_action).edit?)
        end
      end

      describe 'a lead task' do
        before do
          seed_engagement_policy
          lead.trigger_event(event_name: 'claim', user: task_owner)
          scheduled_action
        end

        let(:scheduled_action) { lead.scheduled_actions.first }

        it 'should allow admin access' do
          assert(ScheduledActionPolicy.new(team1_manager1, scheduled_action).edit?)
        end

        it 'should allow owner acces' do
          assert(ScheduledActionPolicy.new(task_owner, scheduled_action).edit?)
        end

        it 'should allow nonowner access by same team' do
          refute(scheduled_action.personal_task?)
          assert(ScheduledActionPolicy.new(team1_agent2, scheduled_action).edit?)
        end

        it 'should disallow nonowner access outside of team' do
          refute(ScheduledActionPolicy.new(team2_agent1, scheduled_action).edit?)
        end
      end

    end

    describe 'completion_form?' do

      let(:task_owner) { team1_agent1 }
      let(:lead) { create(:lead, user: task_owner, property: task_owner.team.properties.first)}

      describe 'a personal task' do
        let(:scheduled_action) { ScheduledAction.create(user: task_owner, target: task_owner )}

        it 'should allow admin access' do
          assert(ScheduledActionPolicy.new(team1_manager1, scheduled_action).completion_form?)
        end

        it 'should allow owner acces' do
          assert(ScheduledActionPolicy.new(task_owner, scheduled_action).completion_form?)
        end

        it 'should disallow nonowner access by same team' do
          refute(ScheduledActionPolicy.new(team1_agent2, scheduled_action).completion_form?)
        end

        it 'should disallow nonowner access outside of team' do
          refute(ScheduledActionPolicy.new(team2_agent1, scheduled_action).completion_form?)
        end
      end

      describe 'a lead task' do
        before do
          seed_engagement_policy
          lead.trigger_event(event_name: 'claim', user: task_owner)
          scheduled_action
        end

        let(:scheduled_action) { lead.scheduled_actions.first }

        it 'should allow admin access' do
          assert(ScheduledActionPolicy.new(team1_manager1, scheduled_action).completion_form?)
        end

        it 'should allow owner acces' do
          assert(ScheduledActionPolicy.new(task_owner, scheduled_action).completion_form?)
        end

        it 'should allow nonowner access by same team' do
          refute(scheduled_action.personal_task?)
          assert(ScheduledActionPolicy.new(team1_agent2, scheduled_action).completion_form?)
        end

        it 'should disallow nonowner access outside of team' do
          refute(ScheduledActionPolicy.new(team2_agent1, scheduled_action).completion_form?)
        end
      end
    end

    describe 'complete?' do

      let(:task_owner) { team1_agent1 }
      let(:lead) { create(:lead, user: task_owner, property: task_owner.team.properties.first)}

      describe 'a personal task' do
        let(:scheduled_action) { ScheduledAction.create(user: task_owner, target: task_owner )}

        it 'should allow admin access' do
          assert(ScheduledActionPolicy.new(team1_manager1, scheduled_action).complete?)
        end

        it 'should allow owner acces' do
          assert(ScheduledActionPolicy.new(task_owner, scheduled_action).complete?)
        end

        it 'should disallow nonowner access by same team' do
          refute(ScheduledActionPolicy.new(team1_agent2, scheduled_action).complete?)
        end

        it 'should disallow nonowner access outside of team' do
          refute(ScheduledActionPolicy.new(team2_agent1, scheduled_action).complete?)
        end
      end

      describe 'a lead task' do
        before do
          seed_engagement_policy
          lead.trigger_event(event_name: 'claim', user: task_owner)
          scheduled_action
        end

        let(:scheduled_action) { lead.scheduled_actions.first }

        it 'should allow admin access' do
          assert(ScheduledActionPolicy.new(team1_manager1, scheduled_action).complete?)
        end

        it 'should allow owner acces' do
          assert(ScheduledActionPolicy.new(task_owner, scheduled_action).complete?)
        end

        it 'should allow nonowner access by same team' do
          refute(scheduled_action.personal_task?)
          assert(ScheduledActionPolicy.new(team1_agent2, scheduled_action).complete?)
        end

        it 'should disallow nonowner access outside of team' do
          refute(ScheduledActionPolicy.new(team2_agent1, scheduled_action).complete?)
        end
      end
    end

  end

end
