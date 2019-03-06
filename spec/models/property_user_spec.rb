# == Schema Information
#
# Table name: property_users
#
#  id          :uuid             not null, primary key
#  property_id :uuid
#  user_id     :uuid
#  role        :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'rails_helper'

RSpec.describe PropertyUser, type: :model do
  include_context "users"

  let(:property){ create(:property) }
  let(:user) { agent }
  let(:property_user) { build(:property_user, user: user, property: property)}

  describe "associations" do
    it "has a user" do
      expect(property_user.user).to eq(user)
    end

    it "has a property" do
      expect(property_user.property).to eq(property)
    end
  end

  describe "validations" do
    let(:property) { create(:property) }
    let(:property2) { create(:property) }
    let(:user) { create(:user) }

    it "has a role" do
      pu = PropertyUser.new(user: user, property: property, role: 'agent')
      assert(pu.valid?)
      pu.role = nil
      refute(pu.valid?)
    end

    it "is unique within a property" do
      PropertyUser.create(user: user, property: property, role: 'agent')
      pu = PropertyUser.new(user: user, property: property, role: 'manager')
      refute(pu.valid?)
      pu.property = property2
      assert(pu.valid?)
    end
  end

  describe "roles" do
    it "has a role" do
      expect(property_user.role).to eq('agent')
    end

    it "must have a role" do
      assert property_user.valid?
      property_user.role = nil
      refute property_user.valid?
    end

    it "can be an agent" do
      property_user.role = 'agent'
      expect(property_user.role).to eq('agent')
    end

    it "can be a manager" do
      property_user.role = 'manager'
      expect(property_user.role).to eq('manager')
    end

    it "cannot be assigned an invalid role" do
      expect{
        property_user.role = 'invalid role'
      }.to raise_error(ArgumentError)
    end

  end

end
