# frozen_string_literal: true

# Backports of Active Storage security fixes that were only released for
# Rails 7.1+ (this app is on 6.1). Details: doc/security_advisories.md.
# Guarded by spec/lib/security/active_storage_hardening_spec.rb.

# CVE-2026-66066 / GHSA-xr9x-r78c-5hrm
#
# The exploit needs libvips as the variant processor. Pin ImageMagick here so
# that raising `config.load_defaults` to 7.0+ (which switches the default to
# :vips) cannot silently opt the app in.
Rails.application.config.active_storage.variant_processor = :mini_magick

# ruby-vips is only installed as a dependency of image_processing and is never
# loaded. Should that change, libvips (>= 8.13) reads this at initialisation and
# disables its unfuzzed loaders -- the same thing the patched Rails does.
ENV['VIPS_BLOCK_UNTRUSTED'] ||= '1'

# CVE-2025-24293 / GHSA-r4mg-4433-c7g3
#
# Rails 7.1.5.2 dropped these three methods from the default allow list; they
# let a transformation escape the allow list entirely. The app only uses
# `resize`, always with literal arguments.
Rails.application.config.after_initialize do
  ActiveStorage.supported_image_processing_methods -= %w[apply loader saver]
end
