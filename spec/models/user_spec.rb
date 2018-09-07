# == Schema Information
#
# Table name: users
#
#  id                     :uuid             not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  confirmation_token     :string
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string
#  failed_attempts        :integer          default(0), not null
#  unlock_token           :string
#  locked_at              :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  role_id                :uuid
#  timezone               :string           default("UTC")
#

require 'rails_helper'

RSpec.describe User, type: :model do
  include_context "users"

  it "can be created" do
    user = build(:user)
    assert(user.save)
  end

  it "has a name" do
    user = create(:user)
    expect(user.name).to_not be_nil
    expect(user.name).to match(user.first_name)

    user.profile = nil
    expect(user.name).to eq(user.email)
  end

  it "can be sorted by name" do
    user1 = create(:user, profile: build(:user_profile, last_name: 'zzz', first_name: 'aaa'))
    user2 = create(:user, profile: build(:user_profile, last_name: 'zzz', first_name: 'bbb'))
    user3 = create(:user, profile: build(:user_profile, last_name: 'aaa', first_name: 'aaa'))

    expect(User.by_name_asc.to_a).to eq([user3, user1, user2])
  end

  describe "associations" do
    describe "property agents" do
      before { skip "Property Agents are deprecated" }

      let(:property_agent) { create(:property_agent) }

      it "has many property agents" do
        user = property_agent.user
        expect(user.property_agents.count).to eq(1)
      end

      it "has many properties" do
        user = property_agent.user
        expect(user.properties.count).to eq(1)
      end

      it "returns all Users associated with a property" do
        property_agent
        expect(User.agents.count).to eq(1)
      end
    end

    describe "profile" do
      let(:user) { create(:user, profile: build(:user_profile)) }

      it "is automatically created" do
        user = create(:user)
        user.reload
        expect(user.profile).to be_a(UserProfile)
        expect(user.profile.user_id).to eq(user.id)
      end

      describe "is delegated" do
        it "user.name_prefix" do
          refute user.name_prefix.nil?
        end
        it "user.first_name" do
          refute user.first_name.nil?
        end
        it "user.last_name" do
          refute user.last_name.nil?
        end
        it "user.office_phone" do
          refute user.office_phone.nil?
        end
        it "user.cell_phone" do
          refute user.cell_phone.nil?
        end
        it "user.fax" do
          refute user.fax.nil?
        end
        it "user.notes" do
          refute user.notes.nil?
        end
      end
    end
  end

  describe "role" do
    it "can be an administrator" do
      assert administrator.administrator?
      refute administrator.agent?
      refute agent.administrator?
    end

    it "can be an corporate" do
      assert corporate.corporate?
      refute agent.corporate?
    end

    it "can be an agent" do
      assert agent.agent?
      refute agent.corporate?
      refute agent.administrator?
    end

    it "can be a type of administrator" do
      assert administrator.admin?
      assert corporate.admin?
      refute agent.admin?
    end

    it "can be an unprivileged user" do
      refute administrator.user?
      refute corporate.user?
      assert agent.user?
    end
  end

  describe "belonging to a team" do
    include_context 'team_members'

    it "has a membership" do
      team1_agent1
      expect(team1_agent1.membership).to be_a(TeamUser)
    end

    it "has a team" do
      team1_agent1
      expect(team1_agent1.team).to eq(team1)
    end

    it "has many properties" do
      team_property1; team_property2
      expect(team1_agent1.properties.sort_by(&:id)).to eq([team_property1, team_property2].sort_by(&:id))
    end

    it "returns User records not belonging to a team" do
      team_property1; team_property2
      assert(User.count == 0)
      team1_agent1
      team1_agent2
      nonteam_user1 = create(:user)
      nonteam_user2 = create(:user)
      expect(User.without_team.sort_by(&:id)).to eq([nonteam_user1, nonteam_user2].sort_by(&:id))
    end
  end


end
