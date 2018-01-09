require 'rails_helper'

RSpec.describe ApplicationMailer, type: :mailer do
  describe "class" do
    it "can be initialized" do
      ApplicationMailer.new
    end
  end
end

