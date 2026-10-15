# frozen_string_literal: true

# "Sign in with Google" -- the primary way into BlueSky; email/password stays as
# the permanent fallback. See doc/google_sign_in.md.
#
# THE MEMBERSHIP GATE IS THAT THE VERIFIED GOOGLE EMAIL ALREADY MATCHES A users
# ROW. Accounts are never auto-provisioned here; there is no User.create in this
# file and there must never be one. An unknown address is refused and told to ask
# an administrator. There is deliberately no hosted-domain (hd) check -- every
# account is admin-created and nobody can sign themselves up (see
# config/initializers/001_google_sign_in.rb) -- so `email_verified` plus the email
# match is the whole control. See #verified_google_email.
#
# Why email-matching is sound rather than merely tolerated: anyone who can
# receive mail at an address can already take that account over through Devise's
# :recoverable password reset. Google sign-in with email_verified == true rests
# on that exact same trust anchor -- "this person controls this mailbox" -- so it
# introduces no new class of account takeover.
#
# The order of the checks in #google_oauth2 is load-bearing: everything that can
# refuse runs before anything is written to the record.
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # Layer 3 of the fail-closed gate. Not redundant with hiding the button:
  # `devise :omniauthable` generates the callback route unconditionally, so
  # without this check the endpoint stays reachable by anyone who types the URL.
  before_action :ensure_google_sign_in_enabled

  def google_oauth2
    email = verified_google_email
    return refuse(:unverified) if email.blank?
    return refuse(:incomplete) if auth.uid.blank?

    # Matched on `email` only, NEVER on `unconfirmed_email`. With reconfirmable on,
    # a pending address change sits in unconfirmed_email until someone clicks the
    # link sent to it; matching there would sign someone in via an address nobody
    # has confirmed. Stored emails are lowercase (Devise case_insensitive_keys),
    # so this is the same lookup the password path does.
    user = User.find_by(email: email)
    # Never auto-provision. An unknown address is a refusal, not a signup.
    return refuse(:unknown_email) if user.nil?

    # FIRST, before anything else touches the record. User#active_for_authentication?
    # returns true for the system user before any other check, so if its address
    # ever matched a Google account, the checks below would be skipped and whoever
    # controls that mailbox would be signed in AS the system user.
    return refuse(:system_user, user) if user.system?

    return refuse(:identity_mismatch, user) unless google_identity_matches?(user)

    # Deactivation is our only revocation -- we cannot revoke at Google.
    return refuse(:deactivated, user) if user.deactivated?
    return refuse(:no_active_property, user) unless user.member_of_an_active_property?

    # Devise's `confirm` on a record with a pending reconfirmation would APPLY the
    # pending change (email = unconfirmed_email). Google has verified the current
    # address, not that one, so this needs an administrator, not a confirmation.
    return refuse(:pending_reconfirmation, user) if !user.confirmed? && user.pending_reconfirmation?

    return refuse(:save_failed, user) unless prepare_and_save(user)

    # Belt and braces. sign_in would also enforce this -- Devise's activatable
    # after_set_user hook throws :warden for an inactive record -- but checking
    # here refuses with a usable message and a log line, and honours any future
    # guard added to that method.
    return refuse(:inactive, user) unless user.active_for_authentication?

    sign_in(user)
    set_flash_message!(:notice, :success, kind: 'Google')
    redirect_to after_sign_in_path_for(user)
  end

  # OmniAuth-level failures: the user cancelled at Google's consent screen, or the
  # strategy raised (bad state, token exchange failure). The flash lands above the
  # sign-in form and force-opens the password disclosure -- a password is the
  # fallback.
  def failure
    Rails.logger.warn(
      "[google_sign_in] failure strategy=#{failed_strategy&.name.inspect} reason=#{failure_message.inspect}"
    )
    redirect_to new_user_session_path,
                alert: 'Google sign-in was cancelled or could not be completed. ' \
                       'Please try again, or sign in with your email address and password.'
  end

  # Constants are not affected by `private`, so this lives up here.
  REFUSAL_MESSAGES = {
    unverified: "Google couldn't confirm that email address is verified, so we can't sign you in with it.",
    incomplete: "Google didn't send a complete profile, so we can't sign you in with it. Please try again.",
    unknown_email: "There's no BlueSky account for that Google account. Make sure you chose the Google " \
                   'account for your work email address, or ask a BlueSky administrator to add you.',
    system_user: "That account can't sign in with Google.",
    identity_mismatch: 'That email address is already linked to a different Google account. ' \
                       'Please ask a BlueSky administrator to unlink it before signing in with Google.',
    deactivated: 'Your BlueSky account has been deactivated. Please contact a BlueSky administrator.',
    no_active_property: "Your BlueSky account isn't assigned to an active property. " \
                        'Please ask a BlueSky administrator to assign you.',
    pending_reconfirmation: 'Your BlueSky account has an email address change waiting to be confirmed. ' \
                            'Please ask a BlueSky administrator for help.',
    save_failed: 'Your account could not be updated for Google sign-in. Please ask a BlueSky administrator for help.',
    inactive: 'Your BlueSky account is not active. Please contact a BlueSky administrator.'
  }.freeze

  private

  def auth
    @auth ||= request.env['omniauth.auth'] || OmniAuth::AuthHash.new
  end

  def raw_info
    auth.extra&.raw_info || OmniAuth::AuthHash.new
  end

  # The email address, but ONLY if Google asserted it is verified.
  #
  # Read from extra.raw_info rather than info.email on purpose. The strategy's own
  # `verified_email` helper gates info.email on a TRUTHY check of email_verified,
  # and in Ruby the string 'false' is truthy -- so info.email would be populated
  # even for an unverified address. Compared with == true so that anything which
  # is not a real JSON boolean true is a refusal.
  def verified_google_email
    return nil unless raw_info['email_verified'] == true

    raw_info['email'].to_s.strip.downcase.presence
  end

  # Trust-on-first-use pinning of the Google identity.
  #
  # An account with no uid yet is unpinned and will be bound below. An account
  # already pinned to a different `sub` is REFUSED, never silently re-bound:
  # re-binding would turn "someone else now controls that Google address" -- a
  # recycled Workspace account, or a domain takeover -- into a silent successful
  # login. Refusing makes it a loud failure that needs an admin to unlink.
  def google_identity_matches?(user)
    return false if user.uid.present? && (user.provider != GoogleSignIn::PROVIDER || user.uid != auth.uid.to_s)

    # The unique index on [provider, uid] would also catch this, but as a 500 on
    # save. Checking here refuses cleanly instead.
    !User.where(provider: GoogleSignIn::PROVIDER, uid: auth.uid.to_s).where.not(id: user.id).exists?
  end

  # Everything that writes, in one transaction: if the final save fails, the
  # confirmation and unlock are rolled back with it.
  def prepare_and_save(user)
    saved = User.transaction do
      confirm_with_google(user) or raise ActiveRecord::Rollback
      # Lockout exists to stop password guessing. Honouring it here would let
      # anyone who knows a colleague's email address lock them out of BOTH paths
      # on demand, six bad passwords at a time. Google sign-in proves identity
      # on its own, so a lock is lifted once every other check above has passed.
      # Accepted side effect: this also resets an attacker's in-progress failed
      # attempt counter -- harmless, since the attacker gains nothing from it.
      user.unlock_access! if user.access_locked?
      link_google_identity(user)
      sync_name_from_google(user)
      user.save or raise ActiveRecord::Rollback
      true
    end
    saved == true
  rescue ActiveRecord::RecordNotUnique
    # Two simultaneous first sign-ins racing on the [provider, uid] index.
    false
  end

  # New users start unconfirmed: the confirmation email is the invitation, and
  # :confirmable blocks them in active_for_authentication? until they click it.
  # email_verified == true proves control of the mailbox -- exactly what clicking
  # the link proves -- so a Google sign-in confirms them.
  #
  # Devise's `confirm` saves with validate: false, so no password is demanded. A
  # Google-first user therefore ends up confirmed with no password and can only
  # sign in with Google until they use "Forgot your password?".
  #
  # The confirmation token is cleared too. Users::ConfirmationsController sends a
  # confirmed user with no password who opens their confirmation link to a
  # set-password page that signs them in, and Devise never expires or clears that
  # token -- so without this the old email would stay a permanent way in.
  def confirm_with_google(user)
    return true if user.confirmed?
    return false unless user.confirm

    user.confirmation_token = nil
    true
  end

  def link_google_identity(user)
    user.provider = GoogleSignIn::PROVIDER
    user.uid = auth.uid.to_s
    user.google_email = verified_google_email
    user.google_linked_at ||= Time.current
  end

  # Names are diffed against the SHADOW columns -- google_given_name /
  # google_family_name, i.e. what Google last told us -- and never against the
  # stored profile first_name / last_name.
  #
  # Diffing against the stored name would revert an admin's correction on every
  # single login, forever: Google says "Bob", the admin fixes it to "Robert", the
  # next login sees a difference and writes "Bob" back. Diffing against the shadow
  # asks a different question -- did GOOGLE change its mind since last time? --
  # and only then do we overwrite.
  #
  # Blank values are skipped: mononym accounts have no family_name, and '' would
  # wipe a perfectly good stored surname. The profile is saved through the user
  # (accepts_nested_attributes_for, so autosave); every User has one in memory
  # (Users::Profile builds it after_initialize).
  def sync_name_from_google(user)
    given = raw_info['given_name'].to_s.strip
    family = raw_info['family_name'].to_s.strip

    if given.present?
      user.profile.first_name = given if given != user.google_given_name
      user.google_given_name = given
    end

    if family.present?
      user.profile.last_name = family if family != user.google_family_name
      user.google_family_name = family
    end
  end

  def refuse(reason, user = nil)
    # Logged at warn: a uid mismatch in particular is a security-relevant event
    # and should be findable after the fact. The email logged is whatever Google
    # sent, verified or not.
    Rails.logger.warn(
      "[google_sign_in] refused reason=#{reason} user_id=#{user&.id.inspect} " \
      "uid=#{auth.uid.inspect} email=#{raw_info['email'].inspect}"
    )
    redirect_to new_user_session_path, alert: REFUSAL_MESSAGES.fetch(reason)
  end

  def ensure_google_sign_in_enabled
    return if GoogleSignIn.enabled?

    Rails.logger.warn("[google_sign_in] refused reason=disabled path=#{request.path.inspect}")
    redirect_to new_user_session_path, alert: 'Google sign-in is not enabled.'
  end
end
