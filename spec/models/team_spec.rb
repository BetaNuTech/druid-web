# == Schema Information
#
# Table name: teams
#
#  id          :uuid             not null, primary key
#  name        :string
#  description :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'rails_helper'

RSpec.describe Team, type: :model do
  include_context "team_members"

  describe "validations" do
    let(:team) { build(:team)}

    it "must have a name" do
      assert(team.valid?)
      team.name = nil
      refute(team.valid?)
    end

    it "has an optional description" do
      assert(team.valid?)
      team.description = nil
      assert(team.valid?)
    end

  end

  describe "associations" do
    let(:team) { create(:team) }
    let(:team2) { create(:team) }
    let(:property1) { create(:property) }
    let(:property2) { create(:property, team: team) }
    let(:property3) { create(:property, team: team) }
    let(:property4) { create(:property, team: team2) }
    let(:property5) { create(:property, team: team2) }

    it "has many properties" do
      property1; property2; property3; property4; property5;
      expect(team.properties.sort_by(&:id)).to eq([property2, property3].sort_by(&:id))
      expect(team2.properties.sort_by(&:id)).to eq([property4, property5].sort_by(&:id))
    end

    describe "team with members" do
      before do
        team1_agent1; team1_agent2; team1_lead1
      end

      it "has many members" do
        team1.reload
        expect(team1.members.map(&:id).sort).to eq(
          [team1_agent1, team1_agent2, team1_lead1].map(&:id).sort)
      end

      it "can get a member's teamrole" do
        expect(team1.teamrole_for(team1_lead1)).to eq(lead_teamrole)
      end
    end
  end

  describe "helper methods" do
    it "returns a users team role" do
      team1_agent1
      expect(team1.teamrole_for(team1_agent1)).to eq(Teamrole.agent)
    end

    it "returns the team managers" do
      team1_agent1; team1_lead1; team1_manager1; team1_manager2
      team1.reload
      expect(team1.managers.first).to eq(team1_manager1)
    end

    it "returns the team leads" do
      team1_agent1; team1_lead1; team1_lead2; team1_manager1; team1_manager2
      team1.reload
      expect(team1.leads.first).to eq(team1_lead1)
    end

  end
end
