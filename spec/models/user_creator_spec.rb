require 'rails_helper'

RSpec.describe Users::Creator do
  include_context "team_members"


  describe "creating a new user" do
    describe "without a creator" do
      let(:property) { create(:property, team: team1)}
      let(:user_attributes) { attributes_for(:user, property: property, role_id: property_role.id)}
      let(:params) {
        {
          user: user_attributes,
          team_id: team1.id,
          teamrole_id: agent_teamrole.id,
          property_id: property,
        }
      }

      it "should fail" do
        user_creator = Users::Creator.new(
          params: {
            user: user_attributes,
            property_id: property.id,
            property_role: 'agent',
            team_id: team1.id,
            teamrole_id: agent_teamrole.id,
          },
          creator: nil
        )
        refute(user_creator.valid?)
      end

    end

    describe "as corporate" do
      let(:property) { creator.property }
      let(:user_attributes) { attributes_for(:user, property: property, role_id: property_role.id)}
      let(:creator) { team1_manager1 }

      it "should create a TRM with a property" do
        user_creator = Users::Creator.new(
          params: {
            user: user_attributes,
            property_id: property.id,
            property_role: 'manager',
            team_id: team1.id,
            teamrole_id: lead_teamrole.id
          },
          creator: creator
        )
        assert(user_creator.valid?)
      end

      it "should create a TRM without a property" do
        user_creator = Users::Creator.new(
          params: {
            user: user_attributes,
            team_id: team1.id,
            teamrole_id: lead_teamrole.id
          },
          creator: creator
        )
        assert(user_creator.valid?)
      end

    end

    describe "as a property manager" do
      let(:property) { creator.property }
      let(:user_attributes) { attributes_for(:user, property: property, role_id: property_role.id)}
      let(:creator) { team1_manager1 }
      let(:params) {
        {
          user: user_attributes,
          team_id: team1.id,
          teamrole_id: agent_teamrole.id,
          property_id: property,

        }
      }

      it "should indicate if valid" do
        user_creator = Users::Creator.new(
          params: {
            user: user_attributes,
            property_id: property.id,
            property_role: 'agent',
            team_id: team1.id,
            teamrole_id: Teamrole.agent.id
          },
          creator: creator
        )
        assert(user_creator.valid?)
      end

      it "should fail to create if invalid property" do
        user_creator = Users::Creator.new(
          params: {
            user: user_attributes,
            property_id: 'XXX', # Invalid Property ID
            property_role: 'agent',
            team_id: team1.id,
            teamrole_id: Teamrole.agent.id
          },
          creator: creator
        )
        refute(user_creator.valid?)
        errs = user_creator.errors.to_a
        expect(errs).to eq([ 'Property is missing' ])
        refute(user_creator.save)
      end

      it "should assign the Agent role if an invalid property role is provided" do
        user_creator = Users::Creator.new(
          params: {
            user: user_attributes,
            property_id: property.id,
            property_role: nil, # Invalid property role
            team_id: team1.id,
            teamrole_id: Teamrole.agent.id
          },
          creator: creator
        )
        assert(user_creator.valid?)
        assert(user_creator.save)
        expect(user_creator.user.property_role).to eq('agent')
      end

      it "should fail to create if invalid team" do
        user_creator = Users::Creator.new(
          params: {
            user: user_attributes,
            property_id: property.id,
            property_role: 'agent',
            team_id: 'XXX',
            teamrole_id: Teamrole.agent.id
          },
          creator: creator
        )
        refute(user_creator.valid?)
        errs = user_creator.errors.to_a
        expect(errs).to eq([ 'Team is missing' ])
        refute(user_creator.save)
      end

      it "should fail to create if invalid teamrole" do
        user_creator = Users::Creator.new(
          params: {
            user: user_attributes,
            property_id: property.id,
            property_role: 'agent',
            team_id: team1.id,
            teamrole_id: 'XXX' # Invalid teamrole
          },
          creator: creator
        )
        refute(user_creator.valid?)
        errs = user_creator.errors.to_a
        expect(errs).to eq([ 'Teamrole is invalid' ])
        refute(user_creator.save)
      end

      it "should fail to create if higher role than creator" do
        user_creator = Users::Creator.new(
          params: {
            user: user_attributes.merge(role_id: administrator_role.id),
            property_id: property.id,
            property_role: 'agent',
            team_id: team1.id,
            teamrole_id: Teamrole.agent.id
          },
          creator: creator
        )
        refute(user_creator.valid?)
        errs = user_creator.errors.to_a
        expect(errs).to eq([ 'Role cannot be set by creator' ])
        refute(user_creator.save)
      end

      it "should fail to create if invalid role" do
        user_creator = Users::Creator.new(
          params: {
            user: user_attributes.merge(role_id: 'XXX'),
            property_id: property.id,
            property_role: 'agent',
            team_id: team1.id,
            teamrole_id: Teamrole.agent.id
          },
          creator: creator
        )
        refute(user_creator.valid?)
        errs = user_creator.errors.to_a
        expect(errs).to eq([ 'Role is missing' ])
        refute(user_creator.save)
      end

      it "should create a new user" do
        user_creator = Users::Creator.new(
          params: {
            user: user_attributes,
            property_id: property.id,
            property_role: 'agent',
            team_id: team1.id,
            teamrole_id: Teamrole.agent.id
          },
          creator: creator
        )

        user_count = User.count

        assert(user_creator.valid?)
        assert(user_creator.save)

        new_user = User.order(created_at: :desc).first
        expect(User.count).to eq(user_count + 1)

        expect(new_user.id).to eq(user_creator.user.id)
        expect(new_user.first_name).to eq(user_attributes[:first_name])
        expect(new_user.last_name).to eq(user_attributes[:last_name])
        expect(new_user.property).to eq(property)
        expect(new_user.assignments.first.property).to eq(property)
        expect(new_user.assignments.first.role).to eq('agent')
        expect(new_user.team).to eq(team1)
        expect(new_user.membership.teamrole).to eq(Teamrole.agent)
      end

      it "should fail to create a user with a missing property" do
        user_creator = Users::Creator.new(
          params: {
            user: user_attributes,
            #property_id: property.id,
            property_id: nil,
            property_role: 'agent',
            team_id: team1.id,
            teamrole_id: Teamrole.agent.id
          },
          creator: creator
        )

        user_count = User.count
        refute(user_creator.save)
        expect(User.count).to eq(user_count)
      end

      it "should fail to create a user with invalid attributes" do
        bad_attrs = user_attributes.merge(email: nil, phone: nil)
        user_creator = Users::Creator.new(
          params: {
            user: bad_attrs,
            property_id: property.id,
            property_role: 'agent',
            team_id: team1.id,
            teamrole_id: Teamrole.agent.id
          },
          creator: creator
        )

        user_count = User.count
        refute(user_creator.save)
        expect(User.count).to eq(user_count)

      end

      it "should assign the user to the property's team" do
        user_creator = Users::Creator.new(
          params: {
            user: user_attributes,
            property_id: property.id,
            property_role: 'agent',
            team_id: nil,
            teamrole_id: Teamrole.agent.id
          },
          creator: creator
        )

        user_count = User.count
        #binding.pry
        assert(user_creator.save)
        expect(user_creator.user.team).to eq(property.team)
      end

      it "should update a user's name" do
        user = agent
        user.profile = UserProfile.new(first_name: 'Blah')
        user.save!
        updated_name = 'Foobar 123'
        updated_name_attrs = {profile_attributes: { first_name: 'Foobar 123' }}
        user_creator = Users::Creator.new(
          params: {
            id: user.id,
            user: updated_name_attrs
          },
          creator: creator
        )
        assert(user_creator.save)
        user.reload
        expect(user.profile.first_name).to eq(updated_name)
      end
    end

    describe "as an administrator" do
      let(:team) { team1_manager1.team }
      let(:property) { team1_manager1.property }
      let(:user_attributes) { attributes_for(:user, property_id: property.id, role_id: administrator_role.id)}
      let(:creator) { administrator }
      let(:params) {
        {
          user: user_attributes,
          team_id: team.id,
          teamrole_id: agent_teamrole.id,
          property_id: property.id,
          property_role: 'agent'
        }
      }

      it "should create an agent" do
        user_creator = Users::Creator.new(params: params, creator: creator)
        assert(user_creator.save)
      end

    end

    describe "as a team admin" do

      let(:team) { team1_agent1.team }
      let(:property) { team1_agent1.property }
      let(:user_attributes) { attributes_for(:user, property_id: property.id, role_id: property_role.id)}
      let(:creator) { team2_lead1 }
      let(:params) {
        {
          user: user_attributes,
          team_id: team.id,
          teamrole_id: agent_teamrole.id,
          property_id: property.id,
          property_role: 'agent'
        }
      }
      let(:user) { agent }

      it "should prevent role reassignment of an existing user in a different property and team" do
        user_creator = Users::Creator.new(params: {id: user.id, user: {role_id: administrator_role.id}}, creator: creator)
        refute user_creator.assign_to_role?
      end
    end
  end


end
