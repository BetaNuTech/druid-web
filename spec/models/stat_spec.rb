require 'rails_helper'

RSpec.describe Stat, type: :model do
  include_context "team_members"

  describe "initialization" do
    before do
      team_property1
      team_property2
      team1_agent1
      team1_agent2
      team1_lead1
      team2
    end

    let(:stat) {
      Stat.new(url: '/foobar',
               filters: {
                  user_ids: [team1_agent1.id],
                  property_ids: [team_property1.id, team_property2.id],
                  team_ids: [team1.id]
                })
    }

    it "can be initialized without filters" do
      s = Stat.new
    end

    it "can be initialized with filters" do
      refute(stat.teams.empty?)
      refute(stat.properties.empty?)
      refute(stat.teams.empty?)
    end


    it "returns filter json" do
      expect(stat.filters_json).to be_a(Hash)
    end

    it "returns lead_states_json" do
      expect(stat.lead_states_json).to be_a(Array)
    end

    it "returns lead_sources_conversion_json" do
      expect(stat.lead_sources_conversion_json).to be_a(Array)
    end

    it "returns property_leads_json" do
      expect(stat.property_leads_json).to be_a(Array)
    end

    it "returns lead_sources_json" do
      expect(stat.lead_sources_json).to be_a(Array)
    end

    it "returns property_leads_json" do
      expect(stat.property_leads_json).to be_a(Array)
    end

    it "returns open_leads_json" do
      expect(stat.open_leads_json).to be_a(Hash)
    end

    it "returns agent_status_json" do
      expect(stat.agent_status_json).to be_a(Hash)
    end

    it "returns recent_activity_json" do
      expect(stat.recent_activity_json).to be_a(Array)
    end

    it "returns notes_created_json" do
      expect(stat.notes_created_json).to be_a(Array)
    end

    it "returns completed_tasks_json" do
      expect(stat.completed_tasks_json).to be_a(Array)
    end

    it "returns messages_sent_json" do
      expect(stat.messages_sent_json).to be_a(Array)
    end

    it "returns property_leads_json" do
      expect(stat.lead_state_changed_records_json).to be_a(Array)
    end
  end

end
