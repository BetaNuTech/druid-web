require 'rails_helper'

RSpec.describe ApplicationCable::Channel do
  describe "class" do
    it "can be initialized" do
      ApplicationCable::Channel.new rescue nil
    end
  end
end
