# frozen_string_literal: true

# View logic for the sign-in page (users/sessions/new).
module SignInHelper
  # Devise alerts that are NOT failures. Every logged-out visitor to a protected
  # page -- including anyone who just opens the site root -- gets
  # `unauthenticated`, and every user idle past `timeout_in` gets `timeout`.
  # Neither means the visitor failed at anything.
  SIGN_IN_PROMPTS = %i[unauthenticated timeout].freeze

  # Whether the collapsed "email address and password" disclosure on the sign-in
  # page starts open.
  #
  # It opens only when the visitor has actually FAILED at something -- a bad
  # password, a locked account, a Google refusal -- because an error rendered
  # above a collapsed form is a dead end: they are told they failed at something
  # they can no longer see, and a password is the fallback. It stays collapsed
  # for the generic prompts above; treating those as failures (as Cobalt first
  # did) means the form is collapsed almost never.
  def password_disclosure_open?
    alert = flash[:alert].to_s.strip
    return false if alert.empty?

    SIGN_IN_PROMPTS.none? { |key| alert == devise_failure_text(key) }
  end

  private

  # The text Devise's failure app would flash for this key: it looks up the
  # resource-scoped key first (devise.failure.user.<key>), then the generic one.
  # Matched by i18n key rather than a literal, so a locale change can't silently
  # turn the generic prompt back into a "failure".
  def devise_failure_text(key)
    I18n.t(:"user.#{key}", scope: 'devise.failure', default: [key], resource_name: :user).to_s.strip
  end
end
