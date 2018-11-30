require 'rails_helper'

RSpec.describe Leads::Adapters::CloudMailin::ZumperParser do

  let(:email_data) {
    JSON.parse File.read(File.join(Rails.root, 'spec', 'support', 'test_data', 'cloudmailin_adapter_zumper_parser_data.json'))
  }

  describe "parsing email data" do
    it "should parse the data" do
      adapter = Leads::Adapters::CloudMailin::ZumperParser

      result = adapter.parse(email_data)
      expect(result[:title]).to eq(nil)
      expect(result[:first_name]).to eq('Josh')
      expect(result[:last_name]).to eq('Pannell')
      expect(result[:email]).to eq('joshuajpannell@gmail.com')
      expect(result[:phone1]).to be_nil
      expect(result[:notes]).to match(/01000166/)
      expect(result[:preference_attributes][:notes]).to match(/We are looking/)
      expect(result[:preference_attributes][:beds]).to eq(2)
      expect(result[:preference_attributes][:baths]).to eq(2)
    end
  end
end
