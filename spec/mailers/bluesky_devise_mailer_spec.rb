require 'rails_helper'

# Devise's confirmation email. For a new account it is the de facto invitation,
# and with Google sign-in on it leads with Google; for an email address change it
# asks the person to confirm the new address.
RSpec.describe BlueskyDeviseMailer, type: :mailer do
  let(:token) { 'a-raw-confirmation-token' }
  let(:new_user) { create(:user) }

  def confirmation_email(user, opts = {})
    BlueskyDeviseMailer.confirmation_instructions(user, token, opts)
  end

  context 'for a new account, with Google sign-in on' do
    before { allow(GoogleSignIn).to receive(:enabled?).and_return(true) }

    it 'leads with Google and keeps confirm-and-set-a-password as the secondary option' do
      mail = confirmation_email(new_user)

      expect(mail.subject).to eq('Welcome to Bluesky! Please confirm your account.')
      expect(mail.body.to_s).to include('Sign in with Google')
      expect(mail.body.to_s).to include('Confirm my account and set a password')
      expect(mail.body.to_s).to include("confirmation_token=#{token}")
    end

    # OmniAuth 2.x refuses GET request-phase initiation and an email link can
    # only ever be a GET, so the button must go to the sign-in page.
    it 'links the Google button to the sign-in page, never the omniauth path' do
      body = confirmation_email(new_user).body.to_s

      expect(body).to include('/users/sign_in')
      expect(body).not_to include('/users/auth/google_oauth2')
    end
  end

  context 'for a new account, with Google sign-in off' do
    before { allow(GoogleSignIn).to receive(:enabled?).and_return(false) }

    it 'is the plain confirmation link' do
      body = confirmation_email(new_user).body.to_s

      expect(body).not_to include('Sign in with Google')
      expect(body).to include('Confirm my account')
      expect(body).to include("confirmation_token=#{token}")
    end
  end

  # reconfirmable: an existing user's new address only applies once confirmed.
  context 'for an email address change' do
    let(:user) do
      create(:user).tap do |u|
        u.update_columns(confirmed_at: Time.current, unconfirmed_email: 'new-address@example.com')
      end
    end

    before { allow(GoogleSignIn).to receive(:enabled?).and_return(true) }

    it 'asks to confirm the new address, without the welcome copy or a Google button' do
      mail = confirmation_email(user, to: user.unconfirmed_email)

      expect(mail.to).to eq(['new-address@example.com'])
      expect(mail.subject).to eq('Please confirm your new Bluesky email address.')
      expect(mail.body.to_s).to include('Confirm my new email address')
      expect(mail.body.to_s).to include("confirmation_token=#{token}")
      expect(mail.body.to_s).not_to include('Welcome to Bluesky')
      expect(mail.body.to_s).not_to include('Sign in with Google')
    end
  end
end
