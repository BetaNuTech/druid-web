require 'rails_helper'

RSpec.describe "properties/index", type: :view do
  before(:each) do
    assign(:properties, [
      Property.create!(
        :name => "Name",
        :address1 => "Address1",
        :address2 => "Address2",
        :address3 => "Address3",
        :city => "City",
        :state => "State",
        :zip => "Zip",
        :country => "Country",
        :organization => "Organization",
        :contact_name => "Contact Name",
        :phone => "Phone",
        :fax => "Fax",
        :email => "Email",
        :units => 2,
        :notes => "MyText"
      ),
      Property.create!(
        :name => "Name",
        :address1 => "Address1",
        :address2 => "Address2",
        :address3 => "Address3",
        :city => "City",
        :state => "State",
        :zip => "Zip",
        :country => "Country",
        :organization => "Organization",
        :contact_name => "Contact Name",
        :phone => "Phone",
        :fax => "Fax",
        :email => "Email",
        :units => 2,
        :notes => "MyText"
      )
    ])
  end

  it "renders a list of properties" do
    render
    assert_select "tr>td", :text => "Name".to_s, :count => 2
    assert_select "tr>td", :text => "Address1".to_s, :count => 2
    assert_select "tr>td", :text => "Address2".to_s, :count => 2
    assert_select "tr>td", :text => "Address3".to_s, :count => 2
    assert_select "tr>td", :text => "City".to_s, :count => 2
    assert_select "tr>td", :text => "State".to_s, :count => 2
    assert_select "tr>td", :text => "Zip".to_s, :count => 2
    assert_select "tr>td", :text => "Country".to_s, :count => 2
    assert_select "tr>td", :text => "Organization".to_s, :count => 2
    assert_select "tr>td", :text => "Contact Name".to_s, :count => 2
    assert_select "tr>td", :text => "Phone".to_s, :count => 2
    assert_select "tr>td", :text => "Fax".to_s, :count => 2
    assert_select "tr>td", :text => "Email".to_s, :count => 2
    assert_select "tr>td", :text => 2.to_s, :count => 2
    assert_select "tr>td", :text => "MyText".to_s, :count => 2
  end
end
