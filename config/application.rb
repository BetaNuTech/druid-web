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

    # Action Text is not used, but `require 'rails/all'` loads it and its engine
    # queues the Trix editor for precompilation. Trix 2 (bundled since Rails 7.1)
    # is written in syntax Uglifier cannot parse, which fails assets:precompile
    # and with it the deploy. Take those assets back out of the build.
    initializer 'bluesky.skip_action_text_assets', after: 'action_text.asset' do |app|
      app.config.assets.precompile -= %w[actiontext.js actiontext.esm.js trix.js trix.css]
    end

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
    # load_defaults 5.1 implies the 6.1 cache format, which Rails 7.2 removed.
    # Rails 7.1 reads and writes format 7.1 too, so a rollback keeps the cache.
    config.active_support.cache_format_version = 7.1
    # load_defaults 5.1 asks for non-URL-safe CSRF tokens, which Rails 7.0
    # deprecates and 7.1 removes. Dropping the override gives URL-safe tokens;
    # tokens already in sessions and open forms still verify.
    config.action_controller.delete(:urlsafe_csrf_tokens)
  end
end
