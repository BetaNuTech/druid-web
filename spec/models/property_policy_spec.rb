require 'rails_helper'

RSpec.describe PropertyPolicy do
  include_context "users"

  describe "policies" do
    let(:property) { create(:property)}

    it "disallows all params for an unroled user" do
      policy = PropertyPolicy.new(unroled_user, property)
      expect(policy.allowed_params).to eq([])
    end

    it "disallows all params for an agent" do
      policy = PropertyPolicy.new(agent, property)
      expect(policy.allowed_params).to eq([])
    end

    it "allows all params for an administrator" do
      policy = PropertyPolicy.new(administrator, property)
      expect(policy.allowed_params).to_not be_empty
    end

    it "allows all params for an operator" do
      policy = PropertyPolicy.new(operator, property)
      expect(policy.allowed_params).to_not be_empty
    end

  end
end
