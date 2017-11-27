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

# Bootstrapping Development

* Run `bin/setup`
* Configuration:
  * Customize `config/database.yml`
  * Customize `.env`

# Running the App for Development

Run: `bundle exec foreman start` to start the Puma application server and DelayedJob background workers.

# Testing

TODO

# Services

## DelayedJob

DelayedJob is started by Foreman, or can be started manually with: `bundle exec rails jobs:work`

## Source Code Management

We are using the GitFlow branch management model. See:
  `https://datasift.github.io/gitflow/IntroducingGitFlow.html`

## Deployment

TODO


