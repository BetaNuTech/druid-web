require 'rails_helper'

RSpec.describe Yardi::Voyager::Data::Prospect, type: :model do

  it "does stuff" do
    data = File.read("doc/yardi/api/samples/GetYardiGuestActivity_Login.xml")

    Yardi::Voyager::Data::Prospect.parse_xml(data)
  end
end
