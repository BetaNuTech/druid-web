ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.

# Fix for Ruby 3.1+ compatibility with Rails 6.1 Logger issue
require 'logger'
unless defined?(::Logger)
  # This shouldn't happen, but just in case
  require 'logger'
end
