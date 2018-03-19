require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  describe "short_date" do
    it "should format a short date" do
      d = DateTime.now
      out = short_date d
      expect(out).to match(d.strftime("%m-%d"))
    end
  end

  describe "long_datetime" do
    it "should format a long date" do
      d = DateTime.now
      out = long_datetime d
      expect(out).to match(d.strftime('%B %e, %Y at %l:%M%p'))
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
      ENV.delete('HTTP_AUTH_NAME')
      ENV.delete('HTTP_AUTH_PASSWORD')
      creds = ApplicationController.http_auth_credentials
      expect(creds[:name]).to_not be_empty
      expect(creds[:password]).to_not be_empty
    end
  end
end
