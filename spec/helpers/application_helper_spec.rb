require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe "short_date" do
    it "should format a short date" do
      d = DateTime.now
      out = short_date d
      expect(out).to match(d.strftime("%m-%d"))
    end
  end

  describe "http_auth_credentials" do
    it "should return credentials from ENVVARS" do
      authname = 'name'
      authpw = 'pw'
      ENV['HTTP_AUTH_NAME'] = authname
      ENV['HTTP_AUTH_PASSWORD'] = authpw

      creds = ApplicationController.http_auth_credentials
      expect(creds[:name]).to eq(authname)
      expect(creds[:password]).to eq(authpw)
    end

    it "should return default values" do
      creds = ApplicationController.http_auth_credentials
      expect(creds[:name]).to_not be_empty
      expect(creds[:password]).to_not be_empty
    end
  end
end
