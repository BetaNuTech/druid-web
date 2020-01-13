require 'rails_helper'

RSpec.describe EngagementPoliciesController do
  include_context "users"
  include_context "engagement_policy"
  render_views

  describe "GET #index" do
    it "should be successful" do
      seed_engagement_policy
      sign_in agent
      get :index
    end
  end
end
