# README

This is the Druid Web Application created by and for BlueStone Properties.

# License

Copyright 2017 BlueStone Properties
This code is proprietary and distribution is strictly prohibited.

# Dependencies

* Ruby version: 2.4.1 (in Gemfile)
* System dependencies
  * Typical Rails 5 dependencies
  * Node.js 8

# Development

## Bootstrapping 

* Run `bin/setup`

## Configuration

* Local Configuration:
  * Customize `config/database.yml`
  * Customize `.env`
  * Customize `.pryrc`
  * ... etc. as indicated by `bin/setup`

Any configuration that is used in production should use environment variables instead of config files.
Config files in this application should be created VERY SPARINGLY and NEVER include secrets. The purpose of
these default configuration files 

Whenever a new config file MUST be created, be sure to:
  * create a `.example` file
  * update `bin/setup`
  * add the config file to `.gitignore`
  * we do not want to create configuration files intended only for development/developers to be checked into source control


## Running

Run: `bundle exec foreman start` to start the Puma application server and DelayedJob background workers.

## Console

Start the Rails console (Pry) with `bundle exec rails console`

Pry configuration can be found in `.pryrc`

# Testing

The following libraries/tools are used for testing:

* RSpec
* FactoryBot
* Guard
* Minicov

## Running Tests

We suggest running `bundle exec guard` in a dedicated console window/tab.
Guard automatically runs tests when files are added/updated.

Run `bundle exec rspec` to run the entire test suite. When Rspec has completed
running the tests, a test coverage report is automatically created in `coverage/index.html`

## Writing Tests

Be sure to create and update FactoryBot factories whenever a database model is created or updated.

## Annotations

Run `bundle exec annotate` to annotate models, tests. and factories with
model/table fields at the beginning of the file.  These annotations can be a
huge help during development and testing to understand the database schema.

TODO

# Services

## DelayedJob

DelayedJob is started by Foreman, or can be started manually with: `bundle exec rails jobs:work`

## Source Code Management

We are using the GitFlow branch management model. See:
  `https://datasift.github.io/gitflow/IntroducingGitFlow.html`

## Deployment

The application is hosted on Heroku. Push to Heroku and run database migrations as needed.

Staging Deployment Example:

```
git push heroku-staging staging:master && \
  heroku run rake db:migrate --app heroku-staging
```
