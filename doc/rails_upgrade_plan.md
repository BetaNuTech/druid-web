# Rails upgrade plan: 6.1 to 7.2

Written November 2026. Goal: reach Rails 7.2 (>= 7.2.3.2), the first release
line still supported that carries the two Active Storage fixes backported in
`config/initializers/active_storage_hardening.rb` (see
`doc/security_advisories.md`). GitHub keeps those two critical alerts open
until `Gemfile.lock` has `activestorage >= 7.2.3.2`.

## Summary

| Hop | Status | Deployed |
| --- | --- | --- |
| Preparation (Zeitwerk, gems that cap Rails) | Done, on `master` | staging v704 (2026-11-10) |
| 6.1.7.10 to 7.0.10 | Done, on `master`; suite matches the 6.1 baseline | staging v704 (2026-11-10) |
| 7.0 to 7.1.6 | Done, on branch `rails-7-1`; suite matches 7.0 | no |
| 7.1 to 7.2.4 | Done, on branch `rails-7-2` (built on `rails-7-1`); suite matches 7.1 | no |
| Webpacker 5 to esbuild | Not started; independent of the Rails hops; 3 to 4 days | |
| Raise `load_defaults` from 5.1 | Not started; not needed to close the alerts; 2 to 3 days | |

The sections below were written before the 7.1 and 7.2 hops were carried out
and are kept as the record of what each needed. Where the work differed from
the plan, "What was done" under that hop says so.

Rails 7.0 and 7.1 are themselves end-of-life, so neither is a place to stop.
Each hop should still be deployed and left to run for a few days before the
next one: the hops are small, and a problem is much easier to attribute when
only one has changed.

"Spiked" means the app was booted, eager-loaded and run through the full spec
suite against that Rails version with throwaway edits; nothing from the
spikes is committed.

## How each hop was judged

`master` is not green, so counts mean nothing. Every run was compared by
diffing the sorted `rspec ./spec/...` failure lines against a clean-`master`
worktree with its own test database and the same `--seed`.

| Run | Seed 4242 | Seed 777 |
| --- | --- | --- |
| master (6.1), three runs | 71, 69, 69 failures | 83 |
| Rails 7.0 branch | 69, identical list to two of the master runs | 83, identical list |
| Rails 7.1 spike | 69 | not run |
| Rails 7.2 spike | 70 (the one new failure is the libvips guard, below) | not run |

The three master runs differ from each other only in
`spec/models/duplicate_leads_spec.rb` (lines 275, 295, 333, 527), which is the
known order-dependent file. The 7.1 and 7.2 spike lists differ from 7.0 only
in that file and in `scheduled_action_policy_spec.rb` (113 against 118, also
known to be order-dependent).

Not covered by any of this: clicking through the app in a browser, a Heroku
slug build, and a production-mode boot (which fails locally on `master` too,
because `config/database.yml` production credentials do not exist here).

## Preparation and the 7.0 hop (done)

Three commits on the upgrade branch. The first two are valid on Rails 6.1 and
were verified there before Rails was touched.

1. **Zeitwerk.** The app was still on the classic autoloader, because
   `load_defaults` is 5.1. Rails 7.0 removes it. Five files broke the naming
   rules: `active_record_extensions.rb` moved to `lib/`, two files that only
   declared a namespace and two empty files were deleted.
2. **Gems that cap Rails.** See the gem table. The Froala editor stays at
   3.2.7: its assets are now in `vendor/assets` (compiled `editor_v2.js` and
   stylesheets are byte-identical) and the S3 upload signature is
   `Froala::S3Upload`, pinned by a spec to the old gem's output.
3. **Rails 7.0.10.** What it took:
   - `attr_encrypted` 3.1 to 4.2 (3.x collides with Active Record 7's own
     encryption). Checked in both directions: SSNs written by either version
     decrypt under the other, so a rollback is safe.
   - `config/initializers/exception_notification.rb` called
     `ErrorNotification` from `app/lib`; Rails 7 refuses to autoload
     reloadable code during boot.
   - `errors[:base] << "..."` is a silent no-op in 7.0. This would have let
     `MarketingSource#create_pending_expense` save a duplicate expense every
     time the rake task ran. No spec covered it; one does now.
   - `legacy_connection_handling = false`, and URL-safe CSRF tokens. Rails
     6.1 and 7.0 both accept either token format, so sessions and open forms
     survive the deploy and a rollback.
   - Two specs: `errors.keys` no longer exists, and controller specs no
     longer keep instance variables between the requests of one example.

`load_defaults` is still 5.1, so cookies, sessions, cache keys and Active
Storage behaviour are unchanged. There are no migrations.

### Before deploying 7.0 to production

- On staging: sign in with Google and with a password, impersonate a user and
  end it, open the lead search and dashboard (the two webpack packs), edit a
  message template (Froala, including an image upload to S3), send an email
  and an SMS, and let the worker process a CloudMailin lead.
- Check the queue for jobs serialized with a class Rails 7.0 removed:
  `heroku run rails runner 'puts Delayed::Job.where("handler LIKE ?", "%ActionMailer::DeliveryJob%").count' -a druid-prod`.
  The app sends mail synchronously today, so this should print 0.
- Rails 7.0 prints 680 `Date#to_s` deprecation warnings in the suite. They
  are the early warning for the 7.1 date-format change below.

## 7.0 to 7.1

Dependency resolution needs one bump: `audited` 5.3.3 to 5.8.0 (5.3 caps
Active Record below 7.1; `audited_changes` is jsonb, so no data concern).

Code changes found by the spike:

- **YAML inside jsonb (the main item).** `Property#appsettings`,
  `UserProfile#appsettings` and `UserProfile#enabled_features` are declared
  `serialize :x` on jsonb columns. Rows hold either a JSON string containing
  YAML or a real JSON object (the development copy has both: all 52 `properties` rows are strings; in
  `user_profiles`, 264 of 265 `appsettings` and 222 of 265 `enabled_features`
  are strings and the rest are objects). Rails 7.1
  hands the object rows to the YAML parser and raises; without a fix 1,757
  examples fail. A coder that loads a String as YAML and passes a Hash
  through brought the suite back to baseline with no data migration.
  Converting the columns to plain jsonb is a clean-up for later, not part of
  the hop.
- **`Date#to_s` changes meaning.** Three CloudMailin parsers (Abodo,
  Rentable, ApartmentList) set `Date::DATE_FORMATS[:default] = "%m/%d/%Y"`
  for the whole process. On 6.1 and 7.0, once one of them has run, every
  `date.to_s` in that dyno returns `11/10/2026`; before that, or on a dyno
  that never parsed such a lead, it returns `2026-11-10`. Rails 7.1 ignores
  the setting, so it is always ISO. The suite does not notice. Callers to
  decide on explicitly: `ProspectStats` cache keys, `Property#office_holidays`,
  `Yardi::Voyager::Data::GuestCard#summary`, `MarketingSources::Report`, the
  marketing source views, and the three parsers themselves (which presumably
  want US dates in the lead notes). Replace the global with `strftime` at the
  call sites that need it.
- Remove `legacy_connection_handling` (7.1 raises if it is set).
- `lib/tasks/leads.rake` uses `to_s(:long)`; 7.1 removes it (`to_fs`).
- Set `config.active_support.cache_format_version = 7.0`. With 5.1 defaults
  the cache format is 6.1, which 7.1 deprecates and 7.2 removes. Format 7.0
  is readable by Rails 7.0, so a rollback still works.
- `Rails.application.secrets` is deprecated: see 7.2.

### What was done (branch `rails-7-1`)

As planned, with one decision: the three parsers' `Date::DATE_FORMATS[:default]`
assignments were deleted rather than replaced. None of those parsers formats a
date (two never set `move_in`, the third parses it with `strptime`), so the
global only ever changed other code's output. `Date#to_s` is now ISO 8601
everywhere, which is also what the SQL in `MarketingSources::Report` and the
`ProspectStats` cache keys were written for. The coder is `YamlInJsonbCoder`.
`config/secrets.yml` was left for the 7.2 hop.

Suite: identical to 7.0 at seeds 4242 and 777 apart from
`scheduled_action_policy_spec.rb:113`, which flips in opposite directions at
the two seeds and is order-dependent on `master`.

## 7.1 to 7.2

Target 7.2.4 (anything >= 7.2.3.2 closes the alerts).

- **`schedulable` 0.0.10 blocks boot.** It calls `serialize :day_of_week, Hash`,
  a form 7.2 removes. The gem is unmaintained (0.0.10 is the latest) and
  small (869 lines); `Note` and `ScheduledAction` use it. Vendor it into
  `lib/` with the one-line fix, or fork it. The spike used a shim.
- **The libvips guard spec fails, and should.** Active Storage 7.2.4
  requires `ruby-vips` itself whenever the gem is installed
  (`active_storage/vips.rb`), so "never loads libvips"
  in `spec/lib/security/active_storage_hardening_spec.rb` no longer holds.
  `variant_processor` stays `:mini_magick` (that example still passes), and
  7.2.3.2+ contains the real fix, so the example should change to assert that
  variants are processed by ImageMagick. Once on 7.2 the initializer's
  allow-list edit is redundant; keep the `:mini_magick` pin.
- **`config/secrets.yml` stops being read.** It only supplies
  `secret_key_base`, from `ENV["SECRET_KEY_BASE"]` in production. Rails 7.2
  reads that variable directly, so production keeps its key; development and
  test fall back to a generated `tmp/local_secret.txt`, which only resets
  local sessions once. Confirm with `heroku config:get SECRET_KEY_BASE` on both apps before the
  hop: if the key changed, every session and encrypted cookie would be
  invalidated. Remove `read_encrypted_secrets` from `production.rb`.
- `cache_format_version` to 7.1 (7.0 is the minimum 7.2 accepts for reads;
  flushing memcache at deploy is the simple alternative).
- `rspec-rails` 6.1 to 7.x (6.1 ran the suite on 7.2 but does not claim to
  support it); `jbuilder` 2.11 to 2.12+ (uses a class 7.2 deprecates).
- 13 `enum name: {...}` declarations are deprecated in 7.2 and removed in
  8.0. Mechanical; do it here or leave it for the 8.0 work.

### What was done (branch `rails-7-2`)

- `schedulable` is vendored in `vendor/gems/schedulable` with the one-line fix.
- `ruby-vips` 2.1.4 to 2.3.0. Not in the original plan: Active Storage 7.2.4
  raises while loading its vips support if libvips is present and `ruby-vips`
  is older than 2.2.1. Locally libvips is absent so nothing raised, but
  whether Heroku's stack image has it was not something to leave to chance.
- The libvips guard now asserts that a variant is handed to
  `ImageProcessing::MiniMagick` and never to `ImageProcessing::Vips`, and that
  Active Storage is >= 7.2.3.2.
- `config/secrets.yml` and `read_encrypted_secrets` removed. `SECRET_KEY_BASE`
  is set on both Heroku apps (checked 2026-11-10).
- `cache_format_version = 7.1`, `rspec-rails` 7.1, `jbuilder` 2.15, and the
  13 enums moved to the positional form.
- One spec change the spike did not show: Active Job 7.2's test helper no
  longer swaps in the test adapter when the app configures one (this app
  configures `:delayed_job`). `resident_block_log_spec.rb` passed only when an
  earlier spec had leaked `queue_adapter = :test`; it now asks for the test
  adapter itself.
- Found only by deploying: the first staging push of 7.2 was rejected at
  `assets:precompile` with an empty `Uglifier::Error`. `rails/all` loads
  Action Text (unused here), whose engine queues `trix.js` for precompilation,
  and the Trix 2 bundled since 7.1 is syntax Uglifier cannot parse. An
  initializer in `config/application.rb`, ordered after `action_text.asset`,
  takes the Action Text and Trix assets back out of the build. The spec suite
  cannot see this; before a deploy, run
  `RAILS_ENV=production SECRET_KEY_BASE=dummy rake assets:precompile` locally.
- Left alone: `delayed_job` 4.1.11 prints one `ActiveSupport::ProxyObject`
  deprecation at boot (removed in Rails 8.0). Bumping the job runner is not
  needed for 7.2.

Suite: identical to 7.1 at seeds 4242 and 777. Checked against the
development copy of production data on 7.2.4: all 265 user profiles, the
properties and 200 schedules load; an SSN encrypted on 6.1 decrypts; the
webpack packs compile.

## Gems checked

| Gem | Locked | 7.0 | 7.1 | 7.2 |
| --- | --- | --- | --- | --- |
| `wysiwyg-rails`, `froala-editor-sdk` | removed | blocked (railties < 7.0); replaced by vendored assets | | |
| `rspec-rails` | 6.1.5 (was 4.1.2) | ok | ok | move to 7.x |
| `action-cable-testing` | removed | obsolete since Rails 6.0 | | |
| `attr_encrypted` | 4.2.0 (was 3.1.0) | 3.x breaks model loading | ok | ok |
| `audited` | 5.3.3 | ok | needs 5.8.0 | ok on 5.8.0 |
| `schedulable` | 0.0.10 | ok | ok, deprecation | blocks boot |
| `webpacker` | 5.4.4 | ok, packs recompiled under 7.0 | loads, suite passes | loads, suite passes |
| `devise` | 4.9.4 | ok | ok | ok |
| `aasm` | 5.4.0 | ok | ok | ok |
| `delayed_job`, `delayed_job_active_record` | 4.1.11, 4.1.7 | ok | ok | ok |
| `flipflop` (Bellingham-DEV fork, 2.6.0) | git | ok | ok | ok |
| `immigrant` | 0.3.6 | ok | ok | ok |
| `pundit` | 2.3.0 | ok | ok | ok |
| `jbuilder` | 2.11.5 | ok | ok | deprecation; bump |
| `ckeditor` | not in the Gemfile | | | |

"ok" for 7.1 and 7.2 means the resolver kept the locked version and the suite
passed in the spike. `rack` stays on 2.2 throughout; Rails 7.1+ allows rack 3
but nothing requires it.

## Webpacker 5 and webpack 4

The `webpacker` gem has no upper bound on Rails and works through 7.2, so it
does not block any hop. It is worth replacing anyway: of the 157 findings
`npm audit` reports today, 125 are in packages installed only because of
`@rails/webpacker`, `webpack`, `webpack-cli` and `webpack-dev-server` (969 of
1,707 installed packages). It also needs
`NODE_OPTIONS=--openssl-legacy-provider` on Node 22.

What webpack builds here is small: 70 files, two real entry points
(`dashboard`, `lead_search`), React 18, and 31 SCSS files imported as CSS
modules. Everything else is already on Sprockets.

| Option | For | Against |
| --- | --- | --- |
| **`jsbundling-rails` + esbuild (recommended)** | Smallest dependency tree; output goes through Sprockets, which the app already uses; removes the dev server, Babel config and Heroku's second `yarn install` | SCSS modules need `esbuild-sass-plugin`; the `javascript_pack_tag` calls in three layouts change; class-name hashing changes, so check the two React screens by eye |
| Shakapacker | Closest to a drop-in: same helpers, same loaders, webpack 5 | Keeps most of the dependency tree and the alerts that come with it |
| Keep Webpacker 5 | No work | 125 audit findings stay; webpack 4 is unmaintained |

Do it as a separate change, before or after the Rails hops, never in the same
deploy as one.

## Framework defaults

The plan keeps `load_defaults 5.1` through all three hops. That is deliberate:
the alerts close on the Rails version, and the defaults carry the risky
behaviour changes. When they are raised later, flip them one at a time from a
`new_framework_defaults` file. The ones that matter here:

- `active_storage.variant_processor` becomes `:vips` at 7.0. The hardening
  initializer pins `:mini_magick` and the guard spec checks it. Keep both.
- `active_support.key_generator_hash_digest_class` (7.0, SHA1 to SHA256) and
  `action_dispatch.cookies_serializer`: change these without a cookie rotator
  and every session is logged out, and the encrypted `true_current_user_id`
  and `user_id` cookies stop decrypting.
- `active_record.default_column_serializer` becomes nil at 7.1 and
  `use_yaml_unsafe_load` should go: both touch the YAML-in-jsonb columns and
  the `schedules.day_of_week` YAML column.
- `action_view.button_to_generates_button_tag` (7.0): the Google sign-in
  control and "Mark As Read" are `button_to`; restyle check only.
- `action_mailer.delivery_job` is already `MailDeliveryJob` on 7.0 (the old
  job classes are gone).

## Risks

1. **The suite is a weak net.** It was red before and stays red in the same
   places; two of the three real 7.0 behaviour changes (`errors <<`, the
   initializer autoload) had no failing spec. Staging checks matter more than
   usual, especially lead intake, messaging and scheduled actions, which is
   where the standing failures are.
2. **`Date#to_s` at 7.1** changes output without raising. Cache keys in
   `ProspectStats` will miss once (harmless); the Yardi guest card summary
   and anything parsing those strings needs a look.
3. **YAML-in-jsonb at 7.1.** The coder is simple, but check production's mix
   of row shapes first:
   `select jsonb_typeof(appsettings), count(*) from properties group by 1`.
4. **In-flight delayed jobs.** Handlers are YAML. Deploy each hop when the
   queue is short and watch `delayed_jobs.last_error` afterwards.
5. **`bin/deploy` has no error handling**: a rejected push still runs
   migrations and moves the tag. Verify the release commit after every hop.
6. **`require_relative` inside `app/lib`** (adapters, parsers, Yardi) and
   `config/features.rb` loading `app/lib/user_preference_strategy.rb` work
   under Zeitwerk but defeat code reloading for those files in development.
   Not a production risk.
7. **Vendored Froala** no longer shows up in dependency scanners. It is the
   same 3.2.7 the gem shipped; moving to Froala 4 needs a new licence key
   check and is a product decision, not part of this upgrade.
