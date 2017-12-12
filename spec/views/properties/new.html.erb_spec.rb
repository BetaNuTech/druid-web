require 'rails_helper'

RSpec.describe "properties/new", type: :view do
  before(:each) do
    assign(:property, Property.new(
      :name => "MyString",
      :address1 => "MyString",
      :address2 => "MyString",
      :address3 => "MyString",
      :city => "MyString",
      :state => "MyString",
      :zip => "MyString",
      :country => "MyString",
      :organization => "MyString",
      :contact_name => "MyString",
      :phone => "MyString",
      :fax => "MyString",
      :email => "MyString",
      :units => 1,
      :notes => "MyText"
    ))
  end

  it "renders new property form" do
    render

    assert_select "form[action=?][method=?]", properties_path, "post" do

      assert_select "input[name=?]", "property[name]"

      assert_select "input[name=?]", "property[address1]"

      assert_select "input[name=?]", "property[address2]"

      assert_select "input[name=?]", "property[address3]"

      assert_select "input[name=?]", "property[city]"

      assert_select "input[name=?]", "property[state]"

      assert_select "input[name=?]", "property[zip]"

      assert_select "input[name=?]", "property[country]"

      assert_select "input[name=?]", "property[organization]"

      assert_select "input[name=?]", "property[contact_name]"

      assert_select "input[name=?]", "property[phone]"

      assert_select "input[name=?]", "property[fax]"

      assert_select "input[name=?]", "property[email]"

      assert_select "input[name=?]", "property[units]"

      assert_select "textarea[name=?]", "property[notes]"
    end
  end
end
