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
#  sign_in_count          :integer          default("0"), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :inet
#  last_sign_in_ip        :inet
#  confirmation_token     :string
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string
#  failed_attempts        :integer          default("0"), not null
#  unlock_token           :string
#  locked_at              :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  role_id                :uuid
#  timezone               :string           default("UTC")
#  deactivated            :boolean          default("false")
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
    it "can be an administrator user" do
      assert administrator.administrator?
      refute administrator.property?
      refute agent.administrator?
    end

    it "can be a corporate user" do
      assert corporate.corporate?
      refute agent.corporate?
    end

    it "can be a property user" do
      assert agent.property?
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

    it "returns User records not belonging to a team" do
      team_property1; team_property2
      User.destroy_all
      assert(User.count == 0)
      team1_agent1
      team1_agent2
      nonteam_user1 = create(:user)
      nonteam_user2 = create(:user)
      expect(User.without_team.sort_by(&:id)).to eq([nonteam_user1, nonteam_user2].sort_by(&:id))
    end
  end

  describe "belonging to property" do
    let(:property1) { create(:property) }
    let(:property2) { create(:property) }
    let(:property3) { create(:property) }
    let(:property1_role) { 'agent' }
    let(:property2_role) { 'manager' }
    let(:user) {
      agent
      agent.assignments = [PropertyUser.new(user: agent, property: property1, role:  property1_role )]
      agent.save!
      agent
    }

    it "belongs to a property via a PropertyUser" do
      expect(user.properties.count).to eq(1)
      expect(user.property).to eq(property1)
    end

    it "has a property role" do
      expect(user.property_role).to eq(property1_role)
    end

    it "returns the user's role for a specific property" do
      user.assignments << PropertyUser.new(user: user, property: property2, role: property2_role)
      user.save!

      expect(user.property_role(property1)).to eq(property1_role)
      expect(user.property_role(property2)).to eq(property2_role)
      expect(user.property_role(property3)).to be_nil
    end
  end


end
