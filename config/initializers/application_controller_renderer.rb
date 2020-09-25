# Be sure to restart your server when you modify this file.

# ActiveSupport::Reloader.to_prepare do
#   ApplicationController.renderer.defaults.merge!(
#     http_host: 'example.org',
#     https: false
#   )
# end
#

# THIS is for support within models
Rails.application.routes.default_url_options = Rails.application.config.action_mailer[:default_url_options]
