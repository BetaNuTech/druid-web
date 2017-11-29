require 'rails_helper'

# Specs in this file have access to a helper object that includes
# the LeadsHelper. For example:
#
# describe LeadsHelper do
#   describe "string concat" do
#     it "concats two strings with spaces" do
#       expect(helper.concat_strings("this","that")).to eq("this that")
#     end
#   end
# end
RSpec.describe ApplicationHelper, type: :helper do
  it "should format a short date" do
    d = DateTime.now
    out = short_date d
    expect(out).to match(d.strftime("%m-%d"))
  end
end
