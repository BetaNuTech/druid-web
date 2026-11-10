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
on GitHub with this document as the justification.
