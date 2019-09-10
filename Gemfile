source 'https://rubygems.org'
ruby '2.6.3'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

gem 'rails', '~> 5.2'
gem 'pg', '~> 0.21'
gem 'mysql2', "~> 0.5"
gem 'puma', '~> 3.12'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '~> 3.2'
gem 'secure_headers', "~> 5.0"

gem 'turbolinks', '~> 5.2'
gem 'jbuilder', '~> 2.8'
gem 'dotenv', '~> 2.7', '>= 2.1.1'
gem 'foreman', '~> 0.85'
gem 'delayed_job_active_record', '~> 4.1'
gem 'awesome_print', '~> 1.8'
gem 'pry-rails', '~> 0.3'
gem 'pry-coolline', '~> 0.2'
gem 'webpacker', '~> 4.0'
gem 'devise', '~> 4.7'
gem 'colorize', '~> 0.8'
gem 'pundit', '~> 1.1'
gem 'audited', '~> 4.8'
gem 'aasm', '~> 4.12'
gem 'pg_search', '~> 2.1'
gem 'attr_encrypted', '~> 3.1'
gem 'ice_cube', '~> 0.16'
gem 'schedulable', "~> 0.0"
gem 'simple_calendar', "~> 2.3"
gem 'httparty', "~> 0.17"
gem 'nokogiri', "~> 1.10"
gem 'liquid', "~> 4.0"
gem 'twilio-ruby', "~> 5.22"
gem 'kaminari', "~> 1.1"
gem 'ckeditor', "~> 4.3"
gem 'scout_apm', "~> 2.4"
gem 'exception_notification', "~> 4.3"
gem 'aws-sdk-s3', "~> 1.36"
gem 'nested_form_fields', "~> 0.8"
gem 'dalli', "~> 2.7"
gem 'connection_pool', "~> 2.2"
gem 'premailer', "~> 1.11"
gem 'image_processing', "~> 1.9"
gem 'mini_magick', "~> 4.9"
gem 'delayed_job_web', "~> 1.4"
gem 'jquery-datatables', "~> 1.10"


group :development, :test do
  gem 'pry-doc', "~> 1.0"
  gem 'pry-stack_explorer', '~> 0.4'
  gem 'pry-byebug', '~> 3.5'
  gem 'byebug', '~> 9.1', platforms: [:mri, :mingw, :x64_mingw]
  gem 'bundler-audit', "~> 0.6"
  gem 'faker', '~> 1.9'
  gem 'factory_bot_rails', '~> 4.11', require: false
end

group :test do
  gem 'rspec', "~> 3.8"
  gem 'warden-rspec-rails', '~> 0.2'
  gem 'capybara', '~> 2.18'
  gem 'guard-rspec', '~> 4.7', require: false
  gem 'guard-rake', "~> 1.0", require: false
  gem 'rails-controller-testing', '~> 1.0'
  gem 'rspec-rails', '~> 3.8'
  #gem 'selenium-webdriver', '~> 3.12'
  gem 'simplecov', '~> 0.16'
  gem 'rspec_junit_formatter', "~> 0.4"
  gem 'action-cable-testing', "~> 0.6"
end

group :development do
  gem 'rubocop', '~> 0.67', require: false
  gem 'web-console', '~> 3.7'
  gem 'listen', '~> 3.1', '< 3.2'
  gem 'spring', '~> 2.0'
  gem 'spring-watcher-listen', '~> 2.0'
  gem 'annotate', '~> 2.7'
  gem 'pessimize', '~> 0.4'
  gem 'letter_opener', '~> 1.7'
  gem 'letter_opener_web', '~> 1.3'

  # Profiler
  gem 'rack-mini-profiler', '~> 0.10', require: false
  gem 'memory_profiler', '~> 0.9'
  gem 'flamegraph', '~> 0.9'
  gem 'stackprof', '~> 0.2'
  gem 'fast_stack', '~> 0.2'

  gem 'derailed_benchmarks', "~> 1.3"
end
