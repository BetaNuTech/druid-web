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

FactoryBot.define do
  factory :property do
    name "MyString"
    address1 "MyString"
    address2 "MyString"
    address3 "MyString"
    city "MyString"
    state "MyString"
    zip "MyString"
    country "MyString"
    organization "MyString"
    contact_name "MyString"
    phone "MyString"
    fax "MyString"
    email "MyString"
    units 1
    notes "MyText"
  end
end
