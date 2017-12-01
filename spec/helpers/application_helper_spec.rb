require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe "short_date" do
    it "should format a short date" do
      d = DateTime.now
      out = short_date d
      expect(out).to match(d.strftime("%m-%d"))
    end
  end
end
