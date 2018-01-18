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

      it "allows all params for an operator" do
        policy = UserPolicy.new(operator, new_user)
        expect(policy.allowed_params).to_not be_empty
      end

    end

    describe "assign_to_property?" do
      it "allows an operator to assign to a property" do
        policy = UserPolicy.new(operator, new_user)
        assert policy.assign_to_property?
      end
      it "allows an administrator to assign to a property" do
        policy = UserPolicy.new(administrator, new_user)
        assert policy.assign_to_property?
      end
      it "disallows an agent to assign to a property" do
        policy = UserPolicy.new(agent, new_user)
        refute policy.assign_to_property?
      end
      it "disallows an unroled user to assign to a property" do
        policy = UserPolicy.new(unroled_user, new_user)
        refute policy.assign_to_property?
      end
    end

  end
end
