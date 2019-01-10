require 'rails_helper'

RSpec.describe Leads::Adapters::CloudMailin::AbodoParser do

  let(:email_data) {
    JSON.parse File.read(File.join(Rails.root, 'spec', 'support', 'test_data', 'cloudmailin_adapter_abodo_parser_data.json'))
  }

  describe "parsing email data" do
    it "should parse the data" do
      adapter = Leads::Adapters::CloudMailin::AbodoParser

      result = adapter.parse(email_data)
      expect(result[:title]).to eq(nil)
      expect(result[:first_name]).to eq('Somebody')
      expect(result[:last_name]).to eq('Ecirli')
      expect(result[:email]).to eq('example@icloud.com')
      expect(result[:phone1]).to eq('+15555555555')
      expect(result[:preference_attributes][:notes]).to match(/I found your property/)
      expect(result[:preference_attributes][:notes]).to match(/2 Bedroom/)
      expect(result[:notes]).to match(/Message-ID: <5bb4d56c7e3de_12cb3ff86/)

    end
  end
end
