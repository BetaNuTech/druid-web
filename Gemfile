source 'https://rubygems.org'
ruby '2.4.3'

git_source(:github) do |repo_name|
  repo_name = '#{repo_name}/#{repo_name}' unless repo_name.include?('/')
  'https://github.com/#{repo_name}.git'
end

gem 'rails', '~> 5.1'
gem 'pg', '~> 0.21'
gem 'puma', '~> 3.11'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '~> 3.2'

gem 'turbolinks', '~> 5.0'
gem 'jbuilder', '~> 2.7'
gem 'dotenv', '~> 2.2', '>= 2.1.1'
gem 'foreman', '~> 0.84'
gem 'delayed_job_active_record', '~> 4.1'
gem 'awesome_print', '~> 1.8'
gem 'pry-rails', '~> 0.3'
gem 'pry-coolline', '~> 0.2'
gem 'webpacker', "~> 3.2"
gem 'devise', '~> 4.3'
gem 'colorize', '~> 0.8'
gem 'pundit', '~> 1.1'
gem 'audited', '~> 4.5'
gem 'aasm', '~> 4.12'
gem 'pg_search', "~> 2.1"
gem 'attr_encrypted', "~> 3.1"

group :development, :test do
  gem 'pry-doc', '~> 0.11'
  gem 'pry-stack_explorer', '~> 0.4'
  gem 'pry-byebug', '~> 3.5'
  gem 'byebug', '~> 9.1', platforms: [:mri, :mingw, :x64_mingw]
  gem 'bundler-audit', '~> 0.6'
  gem 'faker', '~> 1.7'
  gem 'factory_bot_rails', '~> 4.8', require: false
end

group :test do
  gem 'warden-rspec-rails', '~> 0.2'
  gem 'capybara', '~> 2.16'
  gem 'guard-rspec', '~> 4.7', require: false
  gem 'rails-controller-testing', '~> 1.0'
  gem 'rspec-rails', '~> 3.7'
  gem 'selenium-webdriver', '~> 3.7'
  gem 'simplecov', '~> 0.15'
end

group :development do
  gem 'rubocop', "~> 0.52", require: false
  gem 'web-console', '~> 3.5'
  gem 'listen', '~> 3.1', '< 3.2'
  gem 'spring', '~> 2.0'
  gem 'spring-watcher-listen', '~> 2.0'
  gem 'annotate', '~> 2.7'
  gem 'pessimize', '~> 0.3'
  gem 'letter_opener', '~> 1.4'
  gem 'letter_opener_web', '~> 1.3'

  # Profiler
  gem 'rack-mini-profiler', '~> 0.10', require: false
  gem 'memory_profiler', '~> 0.9'
  gem 'flamegraph', '~> 0.9'
  gem 'stackprof', '~> 0.2'
  gem 'fast_stack', '~> 0.2'
end
