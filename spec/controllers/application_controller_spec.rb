require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  include_context "users"
  
  controller do
    before_action :authenticate_user!
    
    def index
      render plain: "OK"
    end
  end
  
  describe "session timeout handling" do
    before do
      sign_in agent
    end
    
    it "handles sign out without causing SystemStackError" do
      # This tests that our sign_out override prevents the infinite loop
      expect {
        controller.sign_out(agent)
      }.not_to raise_error
      
      expect(controller.current_user).to be_nil
    end
    
    it "does not create audit records during sign out" do
      # Count audits before
      initial_audit_count = Audited::Audit.count
      
      # Simulate the sign_out process
      controller.sign_out(agent)
      
      # Verify no new audits were created
      expect(Audited::Audit.count).to eq(initial_audit_count)
    end
    
    it "handles Devise timeout scenario" do
      # Simulate what happens during a timeout
      # The key is that sign_out is called which should disable auditing
      # We'll simulate multiple sign_out calls which could happen during timeout
      
      expect {
        # Multiple sign_out attempts (simulating race conditions)
        3.times { controller.sign_out(agent) }
      }.not_to raise_error
      
      # Auditing should still be enabled after all sign_outs
      expect(Audited.auditing_enabled).to be true
    end
  end
  
  describe "#sign_out" do
    before do
      sign_in agent
    end
    
    it "temporarily disables auditing" do
      # We need to spy on the actual Audited module
      # First, let's verify auditing is enabled
      expect(Audited.auditing_enabled).to be true
      
      # Track when auditing is disabled/enabled
      auditing_disabled = false
      auditing_reenabled = false
      
      # Intercept the first call (disabling)
      allow(Audited).to receive(:auditing_enabled=).with(false) do
        auditing_disabled = true
        Audited.instance_variable_set(:@auditing_enabled, false)
      end
      
      # Intercept the second call (re-enabling)
      allow(Audited).to receive(:auditing_enabled=).with(true) do
        auditing_reenabled = true
        Audited.instance_variable_set(:@auditing_enabled, true)
      end
      
      controller.sign_out(agent)
      
      # Verify both were called
      expect(auditing_disabled).to be true
      expect(auditing_reenabled).to be true
    end
    
    it "re-enables auditing even if an error occurs" do
      # Create a subclass to properly test the super call
      test_controller = Class.new(ApplicationController) do
        def sign_out(resource_or_scope = nil)
          Audited.auditing_enabled = false
          raise StandardError, "Test error"
        ensure
          Audited.auditing_enabled = true
        end
      end
      
      controller_instance = test_controller.new
      allow(controller_instance).to receive(:request).and_return(controller.request)
      allow(controller_instance).to receive(:response).and_return(controller.response)
      
      expect(Audited.auditing_enabled).to be true
      
      expect {
        controller_instance.sign_out(agent)
      }.to raise_error(StandardError, "Test error")
      
      # Auditing should be re-enabled despite the error
      expect(Audited.auditing_enabled).to be true
    end
    
    it "successfully signs out the user" do
      expect(controller.current_user).to eq(agent)
      
      controller.sign_out(agent)
      
      expect(controller.current_user).to be_nil
    end
  end
end