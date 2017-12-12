require 'rails_helper'

RSpec.describe "properties/show", type: :view do
  before(:each) do
    @property = assign(:property, Property.create!(
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
    ))
  end

  it "renders attributes in <p>" do
    render
    expect(rendered).to match(/Name/)
    expect(rendered).to match(/Address1/)
    expect(rendered).to match(/Address2/)
    expect(rendered).to match(/Address3/)
    expect(rendered).to match(/City/)
    expect(rendered).to match(/State/)
    expect(rendered).to match(/Zip/)
    expect(rendered).to match(/Country/)
    expect(rendered).to match(/Organization/)
    expect(rendered).to match(/Contact Name/)
    expect(rendered).to match(/Phone/)
    expect(rendered).to match(/Fax/)
    expect(rendered).to match(/Email/)
    expect(rendered).to match(/2/)
    expect(rendered).to match(/MyText/)
  end
end
