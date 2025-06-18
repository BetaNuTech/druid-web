require 'rails_helper'

RSpec.feature "User Logout", type: :feature do
  include_context "users"
  
  let(:user_pw) { 'TestPassword123' }
  
  before do
    agent.password = agent.password_confirmation = user_pw
    agent.confirmed_at = Time.current
    agent.save!
  end
  
  scenario "User can successfully log out" do
    # Login using Devise test helpers
    login_as(agent, scope: :user)
    
    # Visit a protected page to verify we're logged in
    visit authenticated_root_path
    expect(page.status_code).to eq(200)
    
    # Logout using the destroy session path
    page.driver.submit :delete, destroy_user_session_path, {}
    
    # Verify we're logged out by trying to access protected page
    visit authenticated_root_path
    expect(page).to have_current_path(new_user_session_path)
  end
  
  scenario "User is redirected to login after session timeout" do
    # Login using Devise test helpers
    login_as(agent, scope: :user)
    
    # Verify we're logged in
    visit authenticated_root_path
    expect(page.status_code).to eq(200)
    
    # Simulate session expiration
    logout(:user)
    
    # Try to visit protected page - should redirect to login
    visit authenticated_root_path
    expect(page).to have_current_path(new_user_session_path)
  end
  
  scenario "Logout process completes without errors" do
    # This tests that the logout doesn't trigger SystemStackError
    # even with audit logging enabled
    
    # Login
    login_as(agent, scope: :user)
    
    # Verify auditing is enabled
    expect(Audited.auditing_enabled).to be true
    
    # Logout should complete without errors
    expect {
      page.driver.submit :delete, destroy_user_session_path, {}
    }.not_to raise_error
    
    # Verify auditing is still enabled after logout
    expect(Audited.auditing_enabled).to be true
    
    # The key point is that logout completes without SystemStackError,
    # not whether audits are created (some audits may be created for other models)
  end
  
  scenario "Multiple logout attempts don't cause errors" do
    # Login
    login_as(agent, scope: :user)
    
    # Multiple logout attempts should not cause SystemStackError
    expect {
      # First logout
      page.driver.submit :delete, destroy_user_session_path, {}
      
      # Try to logout again (simulating double-click or multiple requests)
      page.driver.submit :delete, destroy_user_session_path, {}
    }.not_to raise_error
    
    # Should still be logged out properly
    visit authenticated_root_path
    expect(page).to have_current_path(new_user_session_path)
  end
end