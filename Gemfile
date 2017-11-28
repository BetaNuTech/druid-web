source 'https://rubygems.org'
ruby '2.4.1'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end


gem 'rails', '~> 5.1'
gem 'pg', '~> 0.21'
gem 'puma', '~> 3.11'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '~> 3.2'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby

gem 'turbolinks', '~> 5.0'
gem 'jbuilder', '~> 2.7'
gem 'dotenv', '~> 2.2', '>= 2.1.1'
gem 'foreman', "~> 0.84"
gem 'pessimize', "~> 0.3"
gem 'delayed_job_active_record', "~> 4.1"
gem 'awesome_print', "~> 1.8"
gem 'pry-rails', "~> 0.3"
gem 'pry-coolline', "~> 0.2"
gem 'pry-doc', "~> 0.11"
gem 'pry-stack_explorer', "~> 0.4"
gem 'pry-byebug', "~> 3.5"

group :development, :test do
  gem 'byebug', "~> 9.1", platforms: [:mri, :mingw, :x64_mingw]
  gem 'capybara', '~> 2.16'
  gem 'selenium-webdriver', "~> 3.7"
  gem 'bundler-audit', '~> 0.6'
  gem 'factory_bot', '~> 4.8', '>= 4.8.2'
  gem 'rspec-rails', "~> 3.7"
  gem 'simplecov', "~> 0.15"
  gem 'guard-rspec', "~> 4.7", require: false
end

group :development do
  gem 'web-console', '~> 3.5'
  gem 'listen', '~> 3.1', '< 3.2'
  gem 'spring', "~> 2.0"
  gem 'spring-watcher-listen', '~> 2.0'
end
