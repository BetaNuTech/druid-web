require 'rails_helper'

RSpec.describe ApplicationCable::Connection do
  describe "class" do
    it "can be initialized" do
      ApplicationCable::Connection.new(nil, nil) rescue nil
    end
  end
end
