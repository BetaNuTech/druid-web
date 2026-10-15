# Sign in with Google

"Sign in with Google" is the primary way into BlueSky. Email/password stays
permanently as a secondary option, collapsed under a disclosure on the sign-in
page -- demoted, never removed. Ported from the Cobalt app (same behaviour and
security reasoning), adapted to how BlueSky differs: `:lockable`,
`:confirmable` with a custom confirm-then-set-password flow, a system user,
names on `user_profiles`, Pundit.

Code: `Users::OmniauthCallbacksController` (the whole gate),
`config/initializers/001_google_sign_in.rb` (`GoogleSignIn.enabled?`),
`config/initializers/devise.rb` (strategy registration), `Users::Devise`
(`:omniauthable`), `users/sessions/new` + `_password_form` and `SignInHelper`
(sign-in page), `devise/mailer/confirmation_instructions`, `User#unlink_google!`
+ `UsersController#unlink_google` + `UserPolicy#unlink_google?` (admin
recovery), `PrivacyController` (`/privacy`), migration
`20261014180000_add_google_sign_in_to_users`.
Specs: `spec/requests/{google_sign_in,sign_in_page,users_unlink_google,privacy,api_token_auth}_spec.rb`,
`spec/helpers/sign_in_helper_spec.rb`, `spec/mailers/bluesky_devise_mailer_spec.rb`.

Built on `omniauth-google-oauth2` + Devise `:omniauthable` +
`omniauth-rails_csrf_protection`; the gems handle state, the token exchange
and ID-token checks, so the app owns only the gate.

## Settings

| Variable | Default | Purpose |
| --- | --- | --- |
| `GOOGLE_SIGN_IN_ENABLED` | off | **The switch.** Only the literal `true` turns it on. |
| `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET` | – | OAuth client from the "BlueSky" Google Cloud project. Both required. |

`GoogleSignIn.enabled?` **fails closed**: off unless the flag is `true` *and*
both credentials are present. It is consulted in three places, none redundant:

1. `config/initializers/devise.rb` -- whether the strategy is registered at all.
2. `users/sessions/new` -- whether the Google button renders.
3. `Users::OmniauthCallbacksController` -- a `before_action` that refuses.

(3) matters because `devise :omniauthable` generates the routes whether or not
the button shows.

The strategy registers at boot, so a flag change needs a restart but no
deploy. **Kill switch** (about 30 seconds; password sign-in unaffected):

```bash
heroku config:set GOOGLE_SIGN_IN_ENABLED=false -a druid-prod
```

## The gate, and why each check is there

`Users::OmniauthCallbacksController#google_oauth2` runs these in order. Everything
that can refuse runs before anything is written; every refusal is logged at
`warn` as `[google_sign_in] refused reason=…`.

1. **`email_verified == true`, strictly**, read from `extra.raw_info` -- never
   `auth.info.email`. The strategy's own `verified_email` helper is truthy, so
   the string `'false'` would pass it.
2. **The email matches an existing user** -- on `email` only, never
   `unconfirmed_email` (a pending, unconfirmed address change). **No user is
   ever created here.** Unknown addresses are told to ask an administrator.
3. **The system user is refused**, first. `User#active_for_authentication?`
   returns true for it before any other check, so without this a Google
   account at its address would sign in *as* the system user.
4. **`uid` (Google's `sub`) is pinned trust-on-first-use.** A later sign-in for
   that email with a different `uid` is refused, never re-bound; a `uid`
   already pinned to another user is refused. Unique index on
   `[provider, uid]`. Recovery is the admin **Unlink Google** button.
5. **Deactivated users are refused** -- our only revocation; we cannot revoke at Google.
6. **Users without an active property are refused** (admins and team admins exempt,
   as on the password path), with a specific message.
7. **Unconfirmed users are confirmed**, because `email_verified` proves mailbox
   control -- what clicking the confirmation link proves. Without this Google
   sign-in fails for exactly the people an admin just created. Devise's
   `confirm` saves with `validate: false`, so no password is demanded: a
   Google-first user ends up confirmed with **no password** and can only use
   Google until they use "Forgot your password?". The confirmation token is
   **cleared** at the same time: `Users::ConfirmationsController#show` sends a
   confirmed, passwordless user who opens that link to a set-password page that
   signs them in, and Devise never expires or clears the token -- the old email
   would otherwise stay a permanent way in.
   An *unconfirmed* user with a pending address change is refused: `confirm`
   would apply the change to an address nobody has confirmed.
8. **A locked account is unlocked.** Lockout stops password guessing; honouring
   it here would let anyone who knows a colleague's address lock them out of
   both paths on demand. Accepted side effect: a successful Google sign-in also
   resets an attacker's in-progress failed-attempt counter.
9. Link the identity and **sync names into `user_profiles` against shadow
   columns** (`google_given_name` / `google_family_name` = what Google last
   said), never against the stored name -- otherwise an admin's correction
   reverts on every sign-in. Blank values are skipped. Then `save` (not
   `save!`: a refusal, not a 500). Steps 7–9 share one transaction.
10. `active_for_authentication?` once more. `sign_in` would also enforce it
    (Devise's activatable `after_set_user` hook), but checking first gives a
    clean, logged refusal.

**Why email-matching is sound:** anyone who can receive mail at an address can
already take that account over through `:recoverable` password reset. Google
sign-in with `email_verified == true` rests on the same trust anchor.

**No hosted-domain (`hd`) check** (decided 2026-10-13): every BlueSky account
is created by an administrator and nobody can sign themselves up -- the same as
the company's other internal Google-SSO apps -- so allowing any domain adds no
exposure. If one is ever wanted, do it in the callback controller against
`raw_info['hd']`, not as the strategy's `hd` option: OmniAuth test mode bypasses
the strategy, so a strategy-level check can't be spec'd. Domain spread:
`User.active.pluck(:email).map { |e| e.split('@').last.downcase }.tally`.

### Strategy options (`config/initializers/devise.rb`)

- `scope: 'email profile'` -- non-sensitive, so the consent screen publishes
  with no verification review.
- `access_type: 'online'` -- the gem defaults to `offline`, which asks for a
  refresh token we never use.
- `prompt: 'select_account'`.
- `overridable_authorize_options: []` -- by default the gem lets query params
  on the request phase override `access_type`, `scope`, `hd`, `prompt` in the
  URL sent to Google. Self-inflicted only, but it would make /privacy untrue.
- `skip_jwt` left at `false` -- that is what checks the ID token's `aud`
  against our client ID. Never set it to `true`.

No access or refresh tokens are stored; `auth.credentials` is ignored.

## Sign-in page

- Google button primary: a `button_to … method: :post` (OmniAuth 2.x refuses
  GET initiation; `omniauth-rails_csrf_protection` checks the POST's token).
  It uses the named route `user_google_oauth2_omniauth_authorize_path`, not
  Devise's `omniauth_authorize_path` helper -- Devise only mixes that in when a
  strategy registered at boot.
- Password form collapsed in a `<details>`, with all recovery links (forgot
  password, resend confirmation, resend unlock) **inside** it.
- The disclosure force-opens only on a real failure (bad password, locked
  account, a Google refusal) -- not on Devise's `unauthenticated` or `timeout`
  prompts, matched by i18n key (`SignInHelper#password_disclosure_open?`).
- The alert renders once, in the card; the view sets
  `content_for :flash_alert_rendered` so the layout's notifications bar skips it.
- Devise's stock omniauth `link_to` loop was removed from `devise/shared/_links`
  (it was a second, broken GET control).
- With the switch off, the original password-first layout.

## Confirmation email

For a new account it is the invitation: with Google on, "Sign in with Google"
links to the **sign-in page** (an email can only produce a GET), and
"Confirm my account and set a password" is secondary. For an email address
change it says so ("Confirm my new email address", its own subject) and has no
Google button.

## Admin: Unlink Google

On the user edit page, for administrators and corporate users who may edit
that user (`UserPolicy#unlink_google?`; never the system user). Clears all six
Google columns via `update!`, so `audited` records it; the next Google sign-in
pins afresh. It is the recovery for "already linked to a different Google
account" refusals.

## Privacy policy (`/privacy`)

Google won't publish the consent screen without a privacy policy on the
homepage's domain, linked from the homepage. For a logged-out visitor the
homepage *is* the sign-in page, which carries the link in the layout footer.
The page is public (spec'd), self-contained (`layout: false`, inline styles, no
scripts; New Relic injection suppressed) and light-only. It covers staff
accounts and Google sign-in; prospect and resident data is stated to be out of
its scope. If the callback, the stored columns, the cookies (Devise
`:rememberable`, `warden_hooks.rb`), Google Analytics or the providers change,
**update the page in the same commit** -- `privacy_spec.rb` ties several of
these together.

## Google Cloud setup

Project **BlueSky** in the bluecoreresidential.com Google Cloud organisation
(not Cobalt's project: the consent screen shows the project's app name).
External audience; scopes `openid`, `userinfo.email`, `userinfo.profile`. Two
Web clients, no JavaScript origins; redirect URIs registered **verbatim**:

| Client | Authorized redirect URIs |
| --- | --- |
| BlueSky production | `https://www.blue-sky.app/users/auth/google_oauth2/callback` |
| BlueSky staging | `https://staging.druidsite.com/users/auth/google_oauth2/callback`, `http://localhost:3000/users/auth/google_oauth2/callback` |

Use `www.blue-sky.app` only -- the apex 301s to `www` before any sign-in.
Authorized domains `blue-sky.app` and `druidsite.com`, each verified in Search
Console (DNS TXT) by a project Owner/Editor. Branding: homepage
`https://www.blue-sky.app/`, privacy `https://www.blue-sky.app/privacy` (must
already be live). Testing mode refuses everyone not on the test-user list, so
**publish** before rollout.

Rollout order: deploy with the switch off (only `/privacy` and the footer link
change) → verify domains → Authorized domains → Branding → redirect URIs →
publish → set credentials → set `GOOGLE_SIGN_IN_ENABLED=true` last.

## Verifying

Never print a secret -- read credentials by length.

```bash
# Strategy options (local, fresh process; needs the switch on in .env)
bundle exec rails runner 'o = Devise.omniauth_configs[:google_oauth2].options; puts o.slice(:scope, :access_type, :prompt, :hd, :skip_jwt, :overridable_authorize_options).inspect'

# Heroku: flag by value, credentials by length
app=druid-prod
heroku config:get GOOGLE_SIGN_IN_ENABLED -a $app
for v in GOOGLE_CLIENT_ID GOOGLE_CLIENT_SECRET; do n=$(heroku config:get $v -a $app | tr -d '\n' | wc -c | tr -d ' '); echo "$v: $n chars"; done
heroku run -a $app -- bin/rails runner 'puts GoogleSignIn.enabled?'

# Privacy page public (expect 200, no redirect)
curl -s -o /dev/null -w "%{http_code} %{redirect_url}\n" https://www.blue-sky.app/privacy

# Refusals and unlinks
heroku logs -a druid-prod -n 1500 | grep '\[google_sign_in\]'
```

## Testing notes

- Specs inject the auth hash through `Rails.application.env_config` as well as
  `OmniAuth.config.mock_auth`, so they pass whether or not the strategy
  registered at boot (that depends on the developer's `.env`). See
  `spec/support/google_sign_in_helper.rb` and the `google_sign_in: true` tag.
- Devise exposes no route to `failure`; the spec calls `OmniAuth.config.on_failure`
  with a hand-built env. Use a Warden *double* there -- constructing a real
  `Warden::Manager` mutates Devise's shared warden config and breaks every
  later request in the process.
- The security guards were mutation-checked: weakening `== true`, re-binding on
  a uid mismatch, dropping the system-user refusal, the token clearing or the
  unlock, force-opening on the generic prompt, or adding authentication to
  `/privacy` each turns a spec red.
