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

  describe "filtering" do
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

    it "should handle missing date_range" do
      expect(stat.date_range).to be_nil
    end

    it "should handle all_time date_range" do
      stat1 = Stat.new(url: '/foobar',
               filters: {
                  user_ids: [team1_agent1.id],
                  property_ids: [team_property1.id, team_property2.id],
                  team_ids: [team1.id],
                  date_range: [ 'all_time' ]
                })
      expect(stat.date_range).to be_nil
      stat1 = Stat.new(url: '/foobar',
               filters: {
                  user_ids: [team1_agent1.id],
                  property_ids: [team_property1.id, team_property2.id],
                  team_ids: [team1.id],
                  date_range: 'all_time'
                })
      expect(stat.date_range).to be_nil
      expect(stat.start_date).to be_nil
    end

    it "should handle 'week' as an array" do
      stat = Stat.new(url: '/foobar',
               filters: {
                  user_ids: [team1_agent1.id],
                  property_ids: [team_property1.id, team_property2.id],
                  team_ids: [team1.id],
                  date_range: ['week']
                })
      expect(stat.date_range).to eq('week')
      expect(stat.start_date.to_date).to eq(1.week.ago.to_date)
      expect(stat.end_date.to_date).to eq(DateTime.now.to_date)
    end

    it "should handle 'week' as a single value" do
      stat = Stat.new(url: '/foobar',
               filters: {
                  user_ids: [team1_agent1.id],
                  property_ids: [team_property1.id, team_property2.id],
                  team_ids: [team1.id],
                  date_range: 'week'
                })
      expect(stat.date_range).to eq('week')
      expect(stat.start_date.to_date).to eq(1.week.ago.to_date)
      expect(stat.end_date.to_date).to eq(DateTime.now.to_date)
    end

    it "should handle '2weeks' as an array" do
      stat = Stat.new(url: '/foobar',
               filters: {
                  user_ids: [team1_agent1.id],
                  property_ids: [team_property1.id, team_property2.id],
                  team_ids: [team1.id],
                  date_range: ['2weeks']
                })
      expect(stat.date_range).to eq('2weeks')
      expect(stat.start_date.to_date).to eq(2.weeks.ago.to_date)
      expect(stat.end_date.to_date).to eq(DateTime.now.to_date)
    end

    it "should handle '2week' as a single value" do
      stat = Stat.new(url: '/foobar',
               filters: {
                  user_ids: [team1_agent1.id],
                  property_ids: [team_property1.id, team_property2.id],
                  team_ids: [team1.id],
                  date_range: '2weeks'
                })
      expect(stat.date_range).to eq('2weeks')
      expect(stat.start_date.to_date).to eq(2.weeks.ago.to_date)
      expect(stat.end_date.to_date).to eq(DateTime.now.to_date)
    end

    it "should handle 'month' as an array" do
      stat = Stat.new(url: '/foobar',
               filters: {
                  user_ids: [team1_agent1.id],
                  property_ids: [team_property1.id, team_property2.id],
                  team_ids: [team1.id],
                  date_range: ['month']
                })
      expect(stat.date_range).to eq('month')
    end

    it "should handle 'month' as a single value" do
      stat = Stat.new(url: '/foobar',
               filters: {
                  user_ids: [team1_agent1.id],
                  property_ids: [team_property1.id, team_property2.id],
                  team_ids: [team1.id],
                  date_range: 'month'
                })
      expect(stat.date_range).to eq('month')
    end

    it "should handle '3months' as an array" do
      stat = Stat.new(url: '/foobar',
               filters: {
                  user_ids: [team1_agent1.id],
                  property_ids: [team_property1.id, team_property2.id],
                  team_ids: [team1.id],
                  date_range: ['3months']
                })
      expect(stat.date_range).to eq('3months')
    end

    it "should handle '3months' as a single value" do
      stat = Stat.new(url: '/foobar',
               filters: {
                  user_ids: [team1_agent1.id],
                  property_ids: [team_property1.id, team_property2.id],
                  team_ids: [team1.id],
                  date_range: '3months'
                })
      expect(stat.date_range).to eq('3months')
    end


    it "should handle 'year' as an array" do
      stat = Stat.new(url: '/foobar',
               filters: {
                  user_ids: [team1_agent1.id],
                  property_ids: [team_property1.id, team_property2.id],
                  team_ids: [team1.id],
                  date_range: ['year']
                })
      expect(stat.date_range).to eq('year')
    end

    it "should handle 'year' as a single value" do
      stat = Stat.new(url: '/foobar',
               filters: {
                  user_ids: [team1_agent1.id],
                  property_ids: [team_property1.id, team_property2.id],
                  team_ids: [team1.id],
                  date_range: 'year'
                })
      expect(stat.date_range).to eq('year')
    end

  end

end
