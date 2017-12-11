require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the LeadSourcesHelper. For example:
#
# describe LeadSourcesHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe LeadSourcesHelper, type: :helper do

  describe "select_supported_parsers" do

    it "should return select options as HTML" do
      out = select_supported_parsers(nil)
      expect(out).to match("option")
    end

    it "should only return supported parsers" do
      out = select_supported_parsers(nil)
      Leads::Adapters::SUPPORTED.each do |adapter|
        expect(out).to match(adapter)
      end
    end

  end
end
