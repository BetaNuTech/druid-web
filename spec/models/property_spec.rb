# == Schema Information
#
# Table name: properties
#
#  id           :uuid             not null, primary key
#  name         :string
#  address1     :string
#  address2     :string
#  address3     :string
#  city         :string
#  state        :string
#  zip          :string
#  country      :string
#  organization :string
#  contact_name :string
#  phone        :string
#  fax          :string
#  email        :string
#  units        :integer
#  notes        :text
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  active       :boolean          default(TRUE)
#

require 'rails_helper'

RSpec.describe Property, type: :model do
  let(:valid_attributes) {
    attributes_for(:property)
  }

  let(:invalid_attributes) {
    attributes_for(:property, name: nil)
  }

  let(:active_property) {
    create(:property, name: 'Active property', active: true)
  }

  let(:inactive_property) {
    create(:property, name: 'Inactive property', active: false)
  }


  describe "validations" do
    it "requires a name" do
      property = Property.new(valid_attributes)
      assert(property.valid?)

      property.name = nil
      refute(property.valid?)
    end
  end

  describe "scopes" do
    it "can be active" do
      active_property; inactive_property
      expect(Property.count).to eq(2)
      assert(active_property.active)
      refute(inactive_property.active)
      expect(Property.active.count).to eq(1)
    end
  end

  describe "associations" do
    context "leads" do
      let(:lead1) {
        create(:lead, property_id: active_property.id)
      }

      let(:lead2) {
        create(:lead, property_id: active_property.id)
      }

      before do
        lead1
        lead2
      end

      it "has many leads" do
        active_property.reload
        expect(active_property.leads.count).to eq(2)
        expect(inactive_property.leads.count).to eq(0)
      end
    end
  end
end
