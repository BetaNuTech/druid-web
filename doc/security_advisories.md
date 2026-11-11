# Security advisories: how each one is handled

Record of dependency advisories that needed more than a routine version bump,
and of the guards that keep them from regressing.

## November 2026: the eleven "critical" Dependabot alerts

### npm (transitive, all build tooling)

None of these packages is in `package.json`; they arrive through
`@rails/webpacker`, `webpack` and `webpack-dev-server`. They run at asset build
time or in the local dev server, not in the browser bundle or the Rails process.

| Alert | Package | Was | Now | How |
| --- | --- | --- | --- | --- |
| #237 | minimist | 1.2.5 | >= 1.2.6 | lockfile bump |
| #230, #231 | loader-utils | 1.4.0, 2.0.0 | >= 1.4.1, >= 2.0.3 | lockfile bump |
| #263 | sha.js | 2.4.11 | >= 2.4.12 | lockfile bump |
| #253, #301 | pbkdf2 | 3.1.2 | >= 3.1.3 | lockfile bump |
| #506 | websocket-driver | 0.7.4 | >= 0.7.5 | lockfile bump |
| #588 | proxy-addr | 2.0.7 | >= 2.0.8 | lockfile bump |
| #515 | tar | 6.2.1 | >= 7.5.19 | `overrides` + `resolutions` |

`tar` has no fixed 6.x release, and `cacache@15` (via
`compression-webpack-plugin`) asks for `^6`. It is forced to 7.x in
`package.json` twice: `overrides` for npm, and `resolutions` for the unpinned
`yarn install` that Heroku's webpacker step runs. `cacache@15` declares `tar`
but never requires it, so the major bump has no code path to break.

Guard: `spec/lib/security/npm_lockfile_spec.rb` fails if `package-lock.json`
ever locks one of these below its patched version.

### Active Storage (#262, #549): patched only in Rails 7.1+ / 7.2+

Rails 6.1 is end-of-life and received neither fix. Until the Rails upgrade,
the fixes are backported in `config/initializers/active_storage_hardening.rb`
and guarded by `spec/lib/security/active_storage_hardening_spec.rb`.

**#262, CVE-2025-24293 (unsafe transformation methods).** Exploitable only
when request input is passed to `#variant`. Every call in the app is
`variant(resize: "<literal>")`; the spec fails if that stops being true. The
initializer also removes `apply`, `loader` and `saver` from the allow list,
which is the whole of the upstream fix.

**#549, CVE-2026-66066 (libvips unfuzzed loaders).** Exploitable only when
libvips processes uploads. This app has never used it: `load_defaults` is 5.1,
so the variant processor is ImageMagick, and Rails 6.1 has no vips analyzer.
`ruby-vips` is installed only because `image_processing` depends on it, and is
never loaded. The initializer pins `variant_processor = :mini_magick` (a later
`load_defaults 7.0` would otherwise switch to vips) and sets
`VIPS_BLOCK_UNTRUSTED`, the workaround the advisory gives for unpatched Rails.
Because the app was never exposed, the advisory's secret rotation does not
apply.

GitHub keeps both alerts open for as long as `Gemfile.lock` has
`activestorage < 7.2.3.2`. They close by upgrading Rails or by dismissing them
on GitHub with this document as the justification. The upgrade is in `doc/rails_upgrade_plan.md`.

Once Rails 7.2.4 is deployed both fixes come from Rails itself. The
initializer stays as a second layer: it still pins `:mini_magick` (which
`load_defaults 7.0` would otherwise change to vips), and its allow-list edit
becomes a no-op. The guard spec's libvips example changed with 7.2, because
Active Storage 7.2 loads `ruby-vips` itself when the gem is installed; it now
checks that variants are processed by ImageMagick and never by libvips.

## November 2026, second pass: patch-level bumps

Everything fixable without a major version change. Full-suite failure lists
were identical before and after (same seed), Jest passed, and the production
webpack build produced the same set of files.

**Gems** (`bundle update --conservative`): nokogiri 1.19.7, rack 2.2.25,
net-imap 0.5.15, crass 1.0.8, concurrent-ruby 1.3.8, loofah 2.25.3,
rails-html-sanitizer 1.7.2, faraday 2.15.1, mail 2.9.1, omniauth 2.3.1,
json 2.21.2, rexml 3.4.4, websocket-driver 0.8.2, addressable 2.9.2,
dalli 3.2.15, aws-sdk-s3 1.241.0 (with aws-sdk-core 3.268.0).

`rack`, `json` and `net-imap` are pinned to their current major lines in the
`Gemfile`. Left unpinned, the same update moved Rack to 3.x (and Sinatra to 4,
json to 3), which is an upgrade of its own.

The AWS SDK jumped 120 releases and no environment but production talks to
S3, so `spec/lib/aws_s3_spec.rb` now exercises the Active Storage S3 service
and the call-recording presigner against the SDK's stubbed client.

**npm**: `npm audit fix` (in-range only), plus raised floors in `package.json`
for the packages shipped to the browser: axios 1.20, lodash 4.18,
react-router 6.30.4, moment 2.31.

### Still open after this pass, and why

- **Rails 7.2.4 itself** (actionpack, activestorage, activesupport,
  actionmailbox, actionview): the November 2026 Rails advisories are patched
  only in 8.0.5.2 and 8.1.4.1. Two concern Active Storage with ImageMagick,
  which this app uses: GHSA-v924-7rp8-4mxh (decoder chosen by uploaded
  filename) and GHSA-f3w6-w445-fwh9 (file write and read in image analysis).
- **Webpacker 5 / webpack 4 / webpack-dev-server 3**: about sixty npm
  advisories (node-forge, postcss 7, svgo 1, serialize-javascript, braces,
  elliptic, ...) only close by moving off Webpacker 5.
- **Major-version gems**: devise 5, secure_headers 7, css_parser 3, and
  sinatra 4 / rack-proxy 1 (both need Rack 3 or the Webpacker move).
- **Direct npm majors**: bootstrap 3 (no fix on 3.x), d3 7, query-string 10.
