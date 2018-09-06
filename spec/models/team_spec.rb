require 'rails_helper'

RSpec.describe Team, type: :model do
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
  end
end
