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

  end
end
