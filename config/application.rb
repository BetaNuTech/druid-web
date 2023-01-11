require_relative 'version'
require_relative 'boot'

require 'rails/all'
require 'dotenv'
Dotenv.load

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BlueskyWeb
  class Application < Rails::Application
    # Before filter for Flipflop dashboard. Replace with a lambda or method name
    # defined in ApplicationController to implement access control.
    config.flipflop.dashboard_access_filter = -> { head :forbidden }

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    config.generators do |g|
      g.orm :active_record, primary_key_type: :uuid
    end

    config.active_job.queue_adapter = :delayed_job
    config.action_view.sanitized_allowed_attributes = ['href', 'title', 'style']
    config.active_record.use_yaml_unsafe_load = true
  end
end
