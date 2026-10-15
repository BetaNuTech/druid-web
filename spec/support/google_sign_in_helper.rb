# Helpers for "Sign in with Google" request specs.
#
# These drive the callback endpoint directly by injecting the auth hash into the
# Rack env, rather than going through OmniAuth's request phase. That is the
# documented Devise technique, and it means the specs behave the same whether or
# not the strategy happened to be registered at boot -- which depends on the
# developer's .env (GOOGLE_SIGN_IN_ENABLED + credentials):
#
#   * registered: OmniAuth test_mode short-circuits the callback to mock_auth;
#   * not registered: there is no middleware, and the env_config injection
#     supplies request.env['omniauth.auth'] instead.
#
# Tag an example group with `google_sign_in: true` to get test mode and cleanup.
module GoogleSignInHelper
  DEFAULT_UID = '110000000000000000001'.freeze
  OTHER_UID   = '229999999999999999992'.freeze

  def google_auth(email:, uid: DEFAULT_UID, email_verified: true, given_name: 'Gina', family_name: 'Google')
    OmniAuth::AuthHash.new(
      provider: GoogleSignIn::PROVIDER,
      uid: uid,
      info: { email: email, first_name: given_name, last_name: family_name },
      extra: {
        raw_info: {
          'sub' => uid,
          'email' => email,
          'email_verified' => email_verified,
          'given_name' => given_name,
          'family_name' => family_name
        }
      }
    )
  end

  def sign_in_with_google(auth)
    OmniAuth.config.mock_auth[GoogleSignIn::PROVIDER.to_sym] = auth
    Rails.application.env_config['devise.mapping'] = Devise.mappings[:user]
    Rails.application.env_config['omniauth.auth'] = auth
    get user_google_oauth2_omniauth_callback_path
  end

  # Warden stores [[id], salt] under this key.
  def warden_user_id
    session['warden.user.user.key']&.first&.first
  end

  def expect_signed_in_as(user)
    expect(warden_user_id).to eq(user.id), "expected #{user.email} to be signed in"
  end

  def expect_refused
    expect(response).to redirect_to(new_user_session_path)
    expect(warden_user_id).to be_nil, 'expected nobody to be signed in'
  end
end

RSpec.configure do |config|
  config.include GoogleSignInHelper, type: :request

  config.around(:each, google_sign_in: true) do |example|
    test_mode_was = OmniAuth.config.test_mode
    OmniAuth.config.test_mode = true
    begin
      example.run
    ensure
      OmniAuth.config.test_mode = test_mode_was
      OmniAuth.config.mock_auth.delete(GoogleSignIn::PROVIDER.to_sym)
      Rails.application.env_config.delete('omniauth.auth')
      Rails.application.env_config.delete('devise.mapping')
    end
  end
end
