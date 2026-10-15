require 'rails_helper'

# users/sessions/new: Google is the primary action and the email/password form
# is demoted to a collapsed disclosure -- never removed.
RSpec.describe 'Sign-in page', type: :request, google_sign_in: true do
  include_context 'users'

  let(:google_form) { 'form[action=?][method=?]' }

  context 'with Google sign-in enabled' do
    before { allow(GoogleSignIn).to receive(:enabled?).and_return(true) }

    it 'leads with Google and collapses the password form' do
      get new_user_session_path

      expect(response).to have_http_status(:ok)
      # A POST form, not a link: OmniAuth 2.x refuses GET initiation.
      assert_select google_form, user_google_oauth2_omniauth_authorize_path, 'post'
      assert_select '.auth__hint', text: /work email address/
      assert_select 'details.auth__disclosure'
      assert_select 'details.auth__disclosure[open]', false,
                    'password form should start collapsed when there is no error'
      # Password login is permanent -- demoted, never removed.
      assert_select 'details.auth__disclosure input[name=?]', 'user[password]'
    end

    # Devise's stock _links partial used to add a second, GET "Sign in with
    # GoogleOauth2" link, which OmniAuth 2.x refuses.
    it 'renders exactly one Google control' do
      get new_user_session_path

      assert_select 'a[href*=?]', '/users/auth/google_oauth2', count: 0
      assert_select google_form, user_google_oauth2_omniauth_authorize_path, 'post', count: 1
    end

    # Recovery only means anything on the password path, so all of it lives
    # inside the disclosure rather than beside the Google button.
    it 'keeps the forgot-password and other recovery links inside the disclosure' do
      get new_user_session_path

      assert_select 'details.auth__disclosure a[href=?]', new_user_password_path
      assert_select 'a[href=?]', new_user_password_path, count: 1
      assert_select 'details.auth__disclosure a[href=?]', new_user_confirmation_path
    end

    # Every logged-out visitor to a protected page gets this prompt. Treating it
    # as a failure would mean the form is collapsed almost never.
    it 'stays collapsed for the generic sign-in prompt' do
      get '/home'
      expect(response).to redirect_to(new_user_session_path)
      follow_redirect!

      expect(flash[:alert]).to eq(I18n.t('devise.failure.unauthenticated'))
      assert_select 'details.auth__disclosure[open]', false
    end

    # An error above a collapsed form is a dead end.
    it 'force-opens after a bad password' do
      agent.update!(password: 'Foobar123', password_confirmation: 'Foobar123')

      post user_session_path, params: { user: { email: agent.email, password: 'wrong-password' } }

      assert_select 'details.auth__disclosure[open]'
    end

    it 'force-opens for a locked account' do
      agent.update!(password: 'Foobar123', password_confirmation: 'Foobar123')
      agent.lock_access!(send_instructions: false)

      post user_session_path, params: { user: { email: agent.email, password: 'Foobar123' } }
      follow_redirect! if response.redirect?

      expect(flash[:alert]).to eq(I18n.t('devise.failure.locked'))
      assert_select 'details.auth__disclosure[open]'
    end

    it 'force-opens after a Google refusal, where a password is the fallback' do
      sign_in_with_google(google_auth(email: 'stranger@example.com'))
      follow_redirect!

      assert_select 'details.auth__disclosure[open]'
    end

    it 'shows the alert once' do
      sign_in_with_google(google_auth(email: 'stranger@example.com'))
      follow_redirect!

      expect(response.body.scan(ERB::Util.html_escape(flash[:alert])).size).to eq(1)
    end
  end

  context 'with Google sign-in disabled' do
    before { allow(GoogleSignIn).to receive(:enabled?).and_return(false) }

    it 'falls back to the password-first layout' do
      get new_user_session_path

      expect(response).to have_http_status(:ok)
      assert_select 'details.auth__disclosure', false
      assert_select '.btn--google', false
      assert_select 'form[action=?] input[name=?]', user_session_path, 'user[password]'
      assert_select 'a[href=?]', new_user_password_path, count: 1
    end
  end
end
