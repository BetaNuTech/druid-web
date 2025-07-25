require 'rails_helper'

RSpec.describe UserPolicy do
  include_context "users"

  describe "policies" do
    let(:new_user){ create(:user)}

    describe "allowed_params" do

      it "disallows all params for an unroled user" do
        policy = UserPolicy.new(unroled_user, new_user)
        expect(policy.allowed_params).to eq([])
      end

      it "allows all params except role for an agent" do
        policy = UserPolicy.new(agent, new_user)
        expect(policy.allowed_params).to_not be_empty
        expect(policy.allowed_params).to_not include(:role_id)
      end

      it "allows all params for an administrator" do
        policy = UserPolicy.new(administrator, new_user)
        expect(policy.allowed_params).to_not be_empty
      end

      it "allows all params for an corporate" do
        policy = UserPolicy.new(corporate, new_user)
        expect(policy.allowed_params).to_not be_empty
      end

    end

    describe "system user restrictions" do
      before(:all) do
        # Ensure system user exists with the administrator role
        unless User.exists?(email: 'system@bluesky.internal')
          admin_role = Role.find_or_create_by!(name: 'Administrator', slug: 'administrator')
          user = User.create!(
            email: 'system@bluesky.internal',
            password: SecureRandom.hex(32),
            role: admin_role,
            confirmed_at: Time.current,
            system_user: true
          )
          user.create_profile!(first_name: 'Bluesky') unless user.profile
        end
      end
      
      let(:system_user) { User.system }

      describe "#edit?" do
        it "returns false for system user regardless of who is trying" do
          expect(UserPolicy.new(administrator, system_user).edit?).to be false
          expect(UserPolicy.new(corporate, system_user).edit?).to be false
          expect(UserPolicy.new(manager, system_user).edit?).to be false
          expect(UserPolicy.new(agent, system_user).edit?).to be false
          expect(UserPolicy.new(system_user, system_user).edit?).to be false
        end

        it "allows normal editing for regular users" do
          regular_user = create(:user)
          expect(UserPolicy.new(administrator, regular_user).edit?).to be true
          expect(UserPolicy.new(regular_user, regular_user).edit?).to be true
        end
      end

      describe "#update?" do
        it "returns false for system user" do
          expect(UserPolicy.new(administrator, system_user).update?).to be false
          expect(UserPolicy.new(system_user, system_user).update?).to be false
        end
      end

      describe "#destroy?" do
        it "returns false for system user regardless of who is trying" do
          expect(UserPolicy.new(administrator, system_user).destroy?).to be false
          expect(UserPolicy.new(corporate, system_user).destroy?).to be false
          expect(UserPolicy.new(manager, system_user).destroy?).to be false
        end

        it "allows normal destruction for regular users by authorized users" do
          regular_user = create(:user, role: Role.find_by(name: 'Agent'))
          expect(UserPolicy.new(administrator, regular_user).destroy?).to be true
        end
      end

      describe "#impersonate?" do
        it "returns false for system user" do
          expect(UserPolicy.new(administrator, system_user).impersonate?).to be false
        end

        it "allows impersonation of regular users by administrators" do
          regular_user = create(:user, role: Role.find_by(name: 'Agent'))
          expect(UserPolicy.new(administrator, regular_user).impersonate?).to be true
        end
      end

      describe "#show?" do
        it "returns false for system user when edit? is false" do
          # Since edit? returns false for system user, show? should also be affected
          # unless the user has special permissions
          expect(UserPolicy.new(agent, system_user).show?).to be false
        end

        it "allows administrators to view system user" do
          expect(UserPolicy.new(administrator, system_user).show?).to be true
        end
      end
    end

  end
end
