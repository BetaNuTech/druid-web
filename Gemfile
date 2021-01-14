source 'https://rubygems.org'
ruby '2.7.1'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 6.0'
gem 'pg', "~> 1.2"
gem 'mysql2', "~> 0.5"
gem 'puma', "~> 4.3"
gem 'sass-rails', "~> 6.0"
gem 'uglifier', "~> 4.2"
gem 'secure_headers', "~> 6.3"
gem 'bundler'

gem 'turbolinks', "~> 5.2"
gem 'jbuilder', "~> 2.10"
gem 'dotenv', "~> 2.7"
gem 'foreman', "~> 0.87"
gem 'delayed_job_active_record', "~> 4.1"
gem 'amazing_print', "~> 1.2"
gem 'pry-rails', "~> 0.3"
gem 'webpacker', "~> 4.3"
gem 'devise', "~> 4.7"
gem 'colorize', "~> 0.8"
gem 'pundit', "~> 2.1"
gem 'audited', "~> 4.9"
gem 'aasm', "~> 5.1"
gem 'pg_search', "~> 2.3"
gem 'attr_encrypted', "~> 3.1"
gem 'ice_cube', "~> 0.16"
gem 'schedulable', "~> 0.0"
gem 'simple_calendar', "~> 2.4"
gem 'httparty', "~> 0.18"
gem 'nokogiri', "~> 1.10"
gem 'liquid', "~> 4.0"
gem 'twilio-ruby', "~> 5.45"
gem 'kaminari', "~> 1.2"
gem 'ckeditor', "~> 4.3"
gem 'scout_apm', "~> 2.6"
gem 'exception_notification', "~> 4.4"
gem 'aws-sdk-s3', "~> 1.87"
gem 'nested_form_fields', "~> 0.8"
gem 'dalli', "~> 2.7"
gem 'connection_pool', "~> 2.2"
gem 'premailer', "~> 1.14"
gem 'image_processing', "~> 1.12"
gem 'mini_magick', "~> 4.11"
gem 'delayed_job_web', "~> 1.4"
gem 'immigrant', "~> 0.3"
gem "wysiwyg-rails", github: 'codeprimate/wysiwyg-rails'
gem 'froala-editor-sdk', "~> 1.4"
gem 'flipflop', github: 'Bellingham-DEV/flipflop'
gem 'descriptive_statistics', "~> 2.5", require: 'descriptive_statistics/safe'
gem 'working_hours', "~> 1.2"


group :development, :test do
  gem 'pry-doc', "~> 1.1"
  gem 'pry-stack_explorer', "~> 0.5"
  gem 'pry-byebug', "~> 3.9"
  gem 'byebug', "~> 11.1"
  gem 'bundler-audit', "~> 0.7"
  gem 'faker', "~> 2.15"
  gem 'factory_bot_rails', "~> 6.1"
end

group :test do
  gem 'rspec', "~> 3.10"
  gem 'warden-rspec-rails', "~> 0.2"
  gem 'capybara', "~> 3.34"
  gem 'guard-rspec', "~> 4.7"
  gem 'guard-rake', "~> 1.0"
  gem 'rails-controller-testing', "~> 1.0"
  gem 'rspec-rails', "~> 4.0"
  gem 'simplecov', "~> 0.20"
  gem 'rspec_junit_formatter', "~> 0.4"
  gem 'action-cable-testing', "~> 0.6"
end

group :development do
  gem 'rubocop', "~> 0.93", require: false
  gem 'rubocop-faker', "~> 1.1", require: false
  gem 'web-console', "~> 4.1"
  gem 'listen', "~> 3.3"
  gem 'spring', "~> 2.1"
  gem 'spring-watcher-listen', "~> 2.0"
  gem 'annotate', "~> 3.1"
  gem 'pessimize', "~> 0.4"
  gem 'letter_opener', "~> 1.7"
  gem 'letter_opener_web', "~> 1.4"

  # Profiler
  gem 'rack-mini-profiler', "~> 2.3", require: false
  gem 'memory_profiler', "~> 0.9"
  gem 'flamegraph', "~> 0.9"
  gem 'stackprof', "~> 0.2"
  gem 'fast_stack', "~> 0.2"

  gem 'derailed_benchmarks', "~> 1.8"
end
