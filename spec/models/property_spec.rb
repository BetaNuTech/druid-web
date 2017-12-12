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
#

require 'rails_helper'

RSpec.describe Property, type: :model do
  let(:valid_attributes) {
    attributes_for(:property)
  }

  let(:invalid_attributes) {
    attributes_for(:property, name: nil)
  }

  describe "validations" do
    it "requires a name" do
      property = Property.new(valid_attributes)
      assert(property.valid?)

      property.name = nil
      refute(property.valid?)
    end
  end
end
