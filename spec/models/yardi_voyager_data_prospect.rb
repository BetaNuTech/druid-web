require 'rails_helper'

RSpec.describe Yardi::Voyager::Data::Prospect do
  TEST_DATA = File.join(Rails.root,"tmp/voyager_guestcards.json")

  let(:test_data) {
    File.read(TEST_DATA)
  }

  it "should load JSON data" do
    expect{
      Yardi::Voyager::Data::Prospect.from_GetYardiGuestActivity_json(nil)
    }.to raise_error(Yardi::Voyager::Data::Error)

    collection = Yardi::Voyager::Data::Prospect.from_GetYardiGuestActivity_json(test_data)
    
  end

end
