require 'rails_helper'

RSpec.describe Users::SessionsController, type: :controller do
  include_context "users"
  render_views

  let(:user_pw) { 'Foobar123' }

  before do
   @request.env["devise.mapping"] = Devise.mappings[:user]
   agent.password = agent.password_confirmation = user_pw
   agent.save!
  end

  describe "when a user is unauthenticated" do
    let(:user_attributes) { attributes_for(:user) }

    describe "visiting a privileged page" do
      before do
        @controller = LeadsController.new
      end

      it "redirects to the login page" do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    describe "visiting the login page" do
      it "allows logging in with valid credentials" do
        post :create, params: {user: {email: agent.email, password: user_pw}}
        expect(response).to redirect_to(authenticated_root_path)
        expect(session["flash"]["flashes"]["notice"]).to eq('Signed in successfully.')
      end

      it "will not authenticate with invalid credentials" do
        post :create, params: {user: {email: agent.email, password: 'wrong password' }}
        expect(response).to be_successful
        expect(session).to be_empty
      end
    end
  end

  describe "sign out behavior" do
    before do
      sign_in agent
    end
    
    describe "DELETE #destroy" do
      it "successfully logs out the user" do
        delete :destroy
        expect(response).to redirect_to(root_path)
        expect(controller.current_user).to be_nil
      end
      
      it "temporarily disables auditing during sign out" do
        # Track auditing state changes
        auditing_disabled = false
        auditing_reenabled = false
        
        # Intercept the calls to auditing_enabled=
        allow(Audited).to receive(:auditing_enabled=).with(false) do
          auditing_disabled = true
          Audited.instance_variable_set(:@auditing_enabled, false)
        end
        
        allow(Audited).to receive(:auditing_enabled=).with(true) do
          auditing_reenabled = true
          Audited.instance_variable_set(:@auditing_enabled, true)
        end
        
        delete :destroy
        
        # Verify both were called
        expect(auditing_disabled).to be true
        expect(auditing_reenabled).to be true
      end
      
      it "does not create audit records during sign out" do
        # Get initial audit count
        initial_audit_count = Audited::Audit.count
        
        delete :destroy
        
        # Verify no new audits were created during logout
        expect(Audited::Audit.count).to eq(initial_audit_count)
      end
      
      it "re-enables auditing even if an error occurs" do
        # Test that auditing is re-enabled even if there's an error during logout
        # We'll simulate this by stubbing a method called during logout to raise an error
        
        # Ensure auditing starts enabled
        expect(Audited.auditing_enabled).to be true
        
        # Mock respond_to_on_destroy to raise an error after sign_out is called
        allow(controller).to receive(:respond_to_on_destroy) do
          # At this point, sign_out has been called, so auditing should be temporarily disabled
          # Now raise an error
          raise StandardError, "Test error during logout"
        end
        
        # Attempt logout, which should raise our error
        expect { delete :destroy }.to raise_error(StandardError, "Test error during logout")
        
        # Despite the error, auditing should be re-enabled by the ensure block
        expect(Audited.auditing_enabled).to be true
      end
    end
  end


end
