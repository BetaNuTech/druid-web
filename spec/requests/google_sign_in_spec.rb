require 'rails_helper'

# "Sign in with Google" -- Users::OmniauthCallbacksController, the whole gate.
# See spec/support/google_sign_in_helper.rb for how the callback is driven.
RSpec.describe 'Sign in with Google', type: :request, google_sign_in: true do
  include_context 'users'

  let(:default_uid) { GoogleSignInHelper::DEFAULT_UID }
  let(:other_uid) { GoogleSignInHelper::OTHER_UID }

  before do
    # The gate is enabled for these specs; the disabled case is asserted
    # explicitly below.
    allow(GoogleSignIn).to receive(:enabled?).and_return(true)
  end

  # An agent whose only property is active, but who has never confirmed their
  # email: exactly the person an admin just created (the confirmation email is
  # the invitation).
  def unconfirmed_agent
    user = create(:user)
    user.update!(role: property_role)
    default_property.assign_user(user: user, role: 'agent')
    user.reload
  end

  describe 'the membership gate' do
    it 'refuses an email with no matching user, and creates nobody' do
      expect {
        sign_in_with_google(google_auth(email: 'stranger@example.com'))
      }.not_to change(User, :count)

      expect_refused
      expect(flash[:alert]).to match(/administrator/i)
    end

    it 'signs in an existing user and pins the Google identity' do
      sign_in_with_google(google_auth(email: agent.email))

      expect_signed_in_as(agent)
      expect(response).to redirect_to(authenticated_root_path)
      agent.reload
      expect(agent.provider).to eq(GoogleSignIn::PROVIDER)
      expect(agent.uid).to eq(default_uid)
      expect(agent.google_email).to eq(agent.email)
      expect(agent.google_linked_at).to be_present
    end

    it 'matches the user case-insensitively on email' do
      sign_in_with_google(google_auth(email: agent.email.upcase))

      expect_signed_in_as(agent)
    end

    # No hosted-domain check, by decision: every account is admin-created. A
    # Google account with no `hd` at all (a consumer account) still signs in if
    # its verified email matches.
    it 'signs in a matching account that has no hosted domain' do
      auth = google_auth(email: agent.email)
      expect(auth.extra.raw_info['hd']).to be_nil

      sign_in_with_google(auth)

      expect_signed_in_as(agent)
    end
  end

  # With no hosted-domain check, email_verified is the whole security control,
  # so it is compared with == true. The strategy's own helper uses a truthy
  # check, under which the STRING 'false' would pass.
  describe 'email_verified' do
    [false, 'true', 'false', 1, nil].each do |bogus|
      it "refuses email_verified=#{bogus.inspect}" do
        sign_in_with_google(google_auth(email: agent.email, email_verified: bogus))

        expect_refused
        expect(agent.reload.uid).to be_nil
      end
    end
  end

  # User#active_for_authentication? returns true for the system user before
  # checking anything else. Refusing it first is what stops a Google account
  # with that address from signing in AS the system user.
  it 'refuses the system user, even though it would otherwise pass every check' do
    system_user = User.system
    # Make it eligible on every OTHER check (an admin needs no property), so the
    # system-user refusal is the only thing that can stop it. Without this a
    # later check refuses it too and the spec passes for the wrong reason.
    system_user.update_columns(role_id: administrator_role.id, confirmed_at: Time.current)
    expect(system_user.reload).to be_member_of_an_active_property
    expect(system_user.active_for_authentication?).to be(true)

    sign_in_with_google(google_auth(email: system_user.email))

    expect_refused
    expect(flash[:alert]).to eq("That account can't sign in with Google.")
    expect(system_user.reload.uid).to be_nil
  end

  it 'refuses a deactivated user, before writing anything' do
    agent.update_columns(deactivated: true)

    sign_in_with_google(google_auth(email: agent.email))

    expect_refused
    expect(flash[:alert]).to match(/deactivated/i)
    expect(agent.reload.uid).to be_nil
  end

  it 'refuses a user with no active property, with a specific message' do
    sign_in_with_google(google_auth(email: unroled_user.email))

    expect_refused
    expect(flash[:alert]).to match(/active property/i)
    expect(unroled_user.reload.uid).to be_nil
  end

  it 'refuses when Google sign-in is disabled, even though the route exists' do
    allow(GoogleSignIn).to receive(:enabled?).and_return(false)

    sign_in_with_google(google_auth(email: agent.email))

    expect_refused
    expect(flash[:alert]).to match(/not enabled/i)
    expect(agent.reload.uid).to be_nil
  end

  describe 'trust-on-first-use pinning' do
    it 'refuses a different uid for an already-pinned account, and never re-binds' do
      agent.update_columns(provider: GoogleSignIn::PROVIDER, uid: default_uid)

      sign_in_with_google(google_auth(email: agent.email, uid: other_uid))

      expect_refused
      expect(flash[:alert]).to match(/different Google account/i)
      # The whole point: the pin is untouched.
      expect(agent.reload.uid).to eq(default_uid)
    end

    it 'refuses a uid already pinned to another user' do
      corporate.update_columns(provider: GoogleSignIn::PROVIDER, uid: default_uid)

      sign_in_with_google(google_auth(email: agent.email, uid: default_uid))

      expect_refused
      # The clean refusal, not the unique index tripping on save.
      expect(flash[:alert]).to match(/different Google account/i)
      expect(agent.reload.uid).to be_nil
      expect(corporate.reload.uid).to eq(default_uid)
    end

    it 'accepts the same uid again on a later sign-in' do
      agent.update_columns(provider: GoogleSignIn::PROVIDER, uid: default_uid)

      sign_in_with_google(google_auth(email: agent.email, uid: default_uid))

      expect_signed_in_as(agent)
    end
  end

  # :confirmable blocks unconfirmed users in active_for_authentication?, and new
  # users start unconfirmed -- so without this, Google sign-in would fail for
  # exactly the people an admin just created.
  describe 'unconfirmed users' do
    it 'confirms them and signs them in' do
      user = unconfirmed_agent
      expect(user).not_to be_confirmed

      sign_in_with_google(google_auth(email: user.email))

      expect_signed_in_as(user)
      expect(user.reload).to be_confirmed
    end

    # Users::ConfirmationsController sends a confirmed user with no password who
    # opens their confirmation link to a set-password page that signs them in,
    # and Devise never clears or expires that token. Clearing it is what stops
    # the emailed link staying a permanent way in.
    it 'clears the confirmation token, so the emailed link stops working' do
      user = unconfirmed_agent
      old_token = user.confirmation_token
      expect(old_token).to be_present

      sign_in_with_google(google_auth(email: user.email))
      expect_signed_in_as(user)
      expect(user.reload.confirmation_token).to be_nil

      delete destroy_user_session_path
      get user_confirmation_path(confirmation_token: old_token)

      expect(response).not_to be_redirect
      expect(response.body).not_to include('reset_password_token')
    end

    # Devise's `confirm` on a record with a pending reconfirmation would apply the
    # pending address change -- an address nobody has confirmed.
    it 'refuses one with a pending email change, leaving the email alone' do
      user = unconfirmed_agent
      user.update_columns(unconfirmed_email: 'somewhere-else@example.com')

      sign_in_with_google(google_auth(email: user.email))

      expect_refused
      expect(flash[:alert]).to match(/email address change/i)
      user.reload
      expect(user).not_to be_confirmed
      expect(user.unconfirmed_email).to eq('somewhere-else@example.com')
    end

    it 'signs in a confirmed user with a pending email change, without applying it' do
      original_email = agent.email
      agent.update_columns(unconfirmed_email: 'somewhere-else@example.com')

      sign_in_with_google(google_auth(email: original_email))

      expect_signed_in_as(agent)
      agent.reload
      expect(agent.email).to eq(original_email)
      expect(agent.unconfirmed_email).to eq('somewhere-else@example.com')
    end
  end

  # Honouring :lockable here would let anyone who knows a colleague's email lock
  # them out of BOTH paths on demand. Google sign-in proves identity on its own.
  it 'unlocks a locked user and signs them in' do
    agent.lock_access!(send_instructions: false)
    agent.update_columns(failed_attempts: 6)
    expect(agent.reload).to be_access_locked

    sign_in_with_google(google_auth(email: agent.email))

    expect_signed_in_as(agent)
    agent.reload
    expect(agent).not_to be_access_locked
    expect(agent.failed_attempts).to eq(0)
  end

  # The bug this guards: diffing Google's name against the STORED name would
  # revert an admin's correction on every login, forever.
  describe 'name sync' do
    before do
      agent.update_columns(
        provider: GoogleSignIn::PROVIDER,
        uid: default_uid,
        google_given_name: 'Bob',   # what Google last told us
        google_family_name: 'Jones'
      )
      agent.profile.update_columns(first_name: 'Robert', last_name: 'Jones') # the admin's correction
    end

    it "preserves an admin's correction when Google has not changed" do
      sign_in_with_google(google_auth(email: agent.email, given_name: 'Bob', family_name: 'Jones'))

      expect_signed_in_as(agent)
      expect(agent.reload.profile.first_name).to eq('Robert')
    end

    it 'applies a change Google made' do
      sign_in_with_google(google_auth(email: agent.email, given_name: 'Bobby', family_name: 'Jones'))

      agent.reload
      expect(agent.profile.first_name).to eq('Bobby')
      expect(agent.google_given_name).to eq('Bobby')
    end

    # Mononym Google accounts have no family_name; '' must not wipe a stored one.
    it 'skips blank values from Google' do
      sign_in_with_google(google_auth(email: agent.email, given_name: 'Cher', family_name: ''))

      agent.reload
      expect(agent.profile.first_name).to eq('Cher')
      expect(agent.profile.last_name).to eq('Jones')
      expect(agent.google_family_name).to eq('Jones')
    end
  end

  it "adopts Google's names on the first link" do
    sign_in_with_google(google_auth(email: agent.email, given_name: 'Gina', family_name: 'Google'))

    agent.reload
    expect(agent.profile.first_name).to eq('Gina')
    expect(agent.profile.last_name).to eq('Google')
    expect(agent.google_given_name).to eq('Gina')
  end

  # OmniAuth-level failures (cancelled at Google, bad state, token exchange)
  # are routed by Devise's OmniAuth.config.on_failure to the controller's
  # `failure` action -- there is no route to call it directly.
  describe 'OmniAuth failures' do
    def call_on_failure
      env = Rack::MockRequest.env_for(user_google_oauth2_omniauth_callback_path)
      env['rack.session'] = ActionController::TestSession.new
      # Outside the middleware stack, so stand in for the Warden proxy the
      # middleware would have supplied (the audited sweeper calls current_user).
      # A double, not a real Manager: constructing one mutates Devise's shared
      # warden config and breaks every later request in the process.
      env['warden'] = instance_double(Warden::Proxy, authenticate: nil)
      env['omniauth.error.type'] = :access_denied
      OmniAuth.config.on_failure.call(env)
    end

    it 'redirects to the sign-in page' do
      status, headers, _body = call_on_failure

      expect(status).to eq(302)
      expect(headers['Location']).to end_with(new_user_session_path)
    end

    it 'still refuses when Google sign-in is disabled' do
      allow(GoogleSignIn).to receive(:enabled?).and_return(false)

      _status, headers, _body = call_on_failure

      expect(headers['Location']).to end_with(new_user_session_path)
    end
  end
end
