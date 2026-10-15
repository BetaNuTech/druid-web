# frozen_string_literal: true

# "Sign in with Google" -- the primary way into BlueSky. Email/password stays
# permanently as a secondary option on the sign-in page. See doc/google_sign_in.md.
#
# Defined in an initializer rather than app/lib so config/initializers/devise.rb
# and the Devise line in Users::Devise can reference it: an autoloaded constant
# is not safe to touch from an initializer under Zeitwerk. The "001_" prefix is
# load order, not decoration -- initializers run in sorted order, and this one
# must come before devise.rb.
#
# GoogleSignIn.enabled? is the single fail-closed gate, consulted in THREE
# places, because any one of them alone leaves a hole:
#
#   1. config/initializers/devise.rb -- whether to register the strategy at all.
#   2. app/views/users/sessions/new.html.erb -- whether to render the button.
#   3. Users::OmniauthCallbacksController -- a before_action that refuses.
#
# (3) is not redundant with (2): `devise :omniauthable` generates the callback
# route unconditionally, so hiding the button would still leave
# /users/auth/google_oauth2/callback reachable by anyone who types it.
#
# There is deliberately NO hosted-domain (hd) check (decided 2026-10-13). Every
# BlueSky account is created by an administrator and nobody can sign themselves
# up -- the same as the company's other internal Google-SSO apps -- so the
# membership gate is "the verified Google email already matches a users row",
# and allowing any domain adds no exposure. If one is ever wanted, do it in the
# callback controller, not as the strategy's `hd` option: OmniAuth test mode
# bypasses the strategy, so a strategy-level check can't be tested. To see the
# current domain spread:
#   User.active.pluck(:email).map { |e| e.split('@').last.downcase }.tally
module GoogleSignIn
  PROVIDER = 'google_oauth2'

  # Only these. Both are non-sensitive, so publishing the consent screen to
  # Production needs no Google verification review.
  SCOPE = 'email profile'

  class << self
    # Fails closed: every condition must be affirmatively met.
    def enabled?
      flag_on? && credentials_present?
    end

    def client_id
      ENV['GOOGLE_CLIENT_ID'].to_s.strip.presence
    end

    def client_secret
      ENV['GOOGLE_CLIENT_SECRET'].to_s.strip.presence
    end

    private

    # Compared as a string: an unset variable, "false", "0" or "yes" are all off.
    def flag_on?
      ENV['GOOGLE_SIGN_IN_ENABLED'].to_s.strip.casecmp?('true')
    end

    def credentials_present?
      client_id.present? && client_secret.present?
    end
  end
end

OmniAuth.config.logger = Rails.logger
