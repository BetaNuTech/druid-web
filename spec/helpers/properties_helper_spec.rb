require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the PropertiesHelper. For example:
#
# describe PropertiesHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe PropertiesHelper, type: :helper do

  it "should return a property address block" do
    property = create(:property)
    out = property_address_block(property)
    expect(out).to match(property.address1)
    expect(out).to match(property.address2)
    expect(out).to match(property.address3)
    expect(out).to match(property.city)
    expect(out).to match(property.state)
    expect(out).to match(property.zip)
    expect(out).to match(property.country)
  end

  it "should return a classname based on property active flag" do
    active_property = create(:property, name: 'active property', active: true)
    inactive_property = create(:property, name: 'inactive_property', active: false)
    expect(property_active_table_row_class(active_property)).to match('active')
    expect(property_active_table_row_class(inactive_property)).to match('inactive')
  end

end
