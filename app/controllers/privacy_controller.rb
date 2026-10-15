# frozen_string_literal: true

# The public privacy policy at /privacy.
#
# Exists because Google will not publish an OAuth consent screen ("Sign in with
# Google") without one, and Google constrains WHERE it lives: on the same domain
# as the consent screen's app homepage (www.blue-sky.app), that domain verified
# as an Authorized domain, and linked from the homepage. For anyone not signed
# in, the homepage is the sign-in page, which carries the link in the layout
# footer. See doc/google_sign_in.md.
#
# MUST be reachable without signing in -- an anonymous visitor, including
# whoever at Google checks the link, has to get the page, not a redirect to the
# sign-in form. ApplicationController has no global authenticate_user! today;
# the skip below documents the requirement and keeps it true if one is ever
# added. spec/requests/privacy_spec.rb asserts it.
#
# Rendered with `layout: false` and self-contained styles, so the page loads no
# analytics, fonts or application assets of its own, and is identical whether
# served here or saved out as a single static file.
class PrivacyController < ApplicationController
  skip_before_action :authenticate_user!, raise: false

  def show
    # New Relic's browser agent is injected into every HTML response by default.
    # Keep this page free of it, so it loads nothing it does not itself describe.
    NewRelic::Agent.ignore_enduser if defined?(NewRelic::Agent)
    render layout: false
  end
end
