# README

This is the Druid Web Application created by and for BlueStone Properties.

# License

Copyright 2017-2018 BlueStone Properties
This code is proprietary and distribution is strictly prohibited.

# Dependencies

* Ruby version: 2.4.1 (in Gemfile)
* System dependencies
  * Typical Rails 5 dependencies
  * Node.js 8
  * npm
  * yarn

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

In development it is recommended to use the `bin/server` script to run the
application. This script does the following:

* Installs any missing gems using `bundler`
* Checks for any security vulnerabilities with `bundle audit check --update`
* Starts Foreman, which executes processes defined in `Procfile.dev`

### Foreman Processes

Foreman will automatically load environment variables as defined in the `.env` file. Be sure to customize this file before running the application.

The following are started by Foreman in development (`Procfile.dev`):

  * *web* Puma application server (configured in `config/puma.rb`)
  * *worker* DelayedJob worker via `bundle exec rails jobs:work`
  * *webpacker* WebPacker dev server (automatically compiles packfiles and reloads the browser when appropriate. This compiles the React component for `Lead#search`)

The following are started by Foreman (or Heroku) in production (`Procfile`):

  * *web* Puma application server
  * *worker* DelayedJob worker

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

# Documentation

Place documentation in `README.md` or in `doc/`.  Guard will automatically any
graphviz dot files using the rake task `rake docs:compile:dot`. This task may
be run in a standalone fashion as well using the pattern `rake docs:compile:dot[doc/filename.dot]`

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

### Deployment Helper

The `bin/deploy` script handles creation of a git tag, deployment of the application to Heroku, and running of migrations on Heroku

For example: `bin/deploy staging` will use the current branch, create a staging-YYYYMMDD tag, push the tag to origin, push the code to the `heroku-staging` origin, then run migrations on the staging application.

## Users

The `User` model corresponds to User identities in Druid.

User login and authentication is powered by Devise. Run the `db:seed` task or create a new user via the console.  For example:

```
new_user = User.create(email: 'newuser@example.com',
                       password: 'ChangeMe123',
                       password_confirmation: 'ChangeMe123')
# Confirm the user via the email link or via the confirm method
new_user.confirm
```

## Authentication, etc.

The User model is backed by the `devise` gem. Providing numerous capabilities:

  * Authentication
  * Account email address confirmation
  * Password Reset
  * Automatic account locking after multiple failed authentication attempts
  * Account unlocking

### Roles

A user may belong to one of three Roles:

  * Administrator: fully privilileged users
  * Operator: site operators
  * Manager: sales agent manager
  * Agent: sales agents with limit management access

### UI

Admins (Role is `administrator` or `operator`) may manage users via a Web UI.

# Production/Staging

## General Configuration

### Environment Variables

```
# Environment Variables
APPLICATION_HOST=staging.druidsite.com (or www.druidsite.com for production)
CRYPTO_KEY=XXX (generate a value using 'rake secret')
LANG=en_US.UTF-8
RACK_ENV=production
RAILS_ENV=production
RAILS_LOG_TO_STDOUT=enabled
RAILS_SERVE_STATIC_FILES=enabled
SECRET_KEY_BASE=XXX (generate a value using 'rake secret')
```

### Seed Data

After the application has been provisioned and deployed and the addons setup, seed the application data.

```
heroku run --app APPNAME rake db:schema:load
heroku run --app APPNAME rake db:seed
```

Immediately login as `admin@example.com` using the password `ChangeMeNow`, then update the admin account to use a secure password. Then change the admin email address. Delete the `agent@example.com` account afterwards.

## Services

### PostgreSQL

PostgreSQL is the primary relational database, used by ActiveRecord.

On Heroku, this service is provisioned as an addon using the 'standard-0' tier.

#### Druid Configuration

```
# Environment Variables
DATABASE_URL=XXX (automatically set by addon configuration)
```

### Papertrail

Papertrail provides log aggregation services.

On Heroku, this service is provisioned as an addon using the 'Choklad' (free) tier.

#### Druid Configuration

```
# Environment Variables
RAILS_LOG_TO_STDOUT=enabled
PAPERTRAIL_API_TOKEN=XXX (automatically set by addon configuration)
```

### ScoutApp

ScoutApp provides performance analysis.

On Heroku, this service is provisioned as an addon using the 'Chairlift' (free) tier.

#### Druid Configuration

* Gem: `scout_apm`

```
# Environment Variables
SCOUT_LOG_LEVEL=WARN
SCOUT_MONITOR=true
SCOUT_KEY=XXX
```

### Mailgun

Mailgun provides outgoing email service for the application, used by ActionMailer.

On Heroku, this service is provisioned as an addon using the 'Starter' (free) tier.

#### Druid Configuration

```
# Environment Variables
MAILGUN_API_KEY=XXX
MAILGUN_DOMAIN=mail.druidsite.com
MAILGUN_PUBLIC_KEY=XXX
MAILGUN_SMTP_LOGIN=postmaster@mail.druidsite.com
MAILGUN_SMTP_PASSWORD=XXX
MAILGUN_SMTP_PORT=587
MAILGUN_SMTP_SERVER=smtp.mailgun.org
```

#### Mailgun Configuration

Validate the `mail.druidsite.com` domain.

### Yardi

Yardi is (historically) used by leasing agents and other employees to manage leads and residents.

An hourly background job imports Lead information into Druid. Ensure that the following job is configured:

Hourly: `rake leads:yardi:import_guestcards`

#### Druid Configuration

```
# Environment Variables
YARDI_VOYAGER_DATABASE=gazv_live
YARDI_VOYAGER_HOST=www.yardiasp14.com
YARDI_VOYAGER_LICENSE=XXX
YARDI_VOYAGER_PASSWORD=XXX
YARDI_VOYAGER_SERVERNAME=gazv_live
YARDI_VOYAGER_USERNAME=druid
YARDI_VOYAGER_VENDORNAME=Druid ILS Guest Card
YARDI_VOYAGER_WEBSHARE=21253beta
```

### Cloudmailin

Cloudmailin provides incoming mail via webhooks. Incoming mail is used by the following features:

  * Lead import from Internet Listing Services
  * Incoming (email) Messages for the Lead Messaging feature

#### Druid Configuration

Webhook requests are authorized and validated with a `token` param. Go to `LeadSource#Show` to view and/or reset the `token`

Incoming messages are processed using a `+` email scheme.

  * Incoming Leads use the code part of the `address+code@cloudmailin.net` address to lookup `PropertyListing` record which associates the Lead with a property.
  * See `Property#Edit` to assign Property Listing ID's/Codes.

```
# Environment Variables
MESSAGE_DELIVERY_REPLY_TO=XXX (use appropriate Cloudmailin address for the environment and Messages feature)
DEBUG_MESSAGE_API=true (logs additional debug information)
```

#### Cloudmailin Configuration

Cloudmailin configuration is separate from Heroku and is performed on the Cloudmailin website (https://cloudmailin.com).
The account email address is 'cobaltcloud@betanutechnologies.com'

```
|-------------+----------------+--------------------------------------+--------------------------------------------------------------|
| Environment | Feature        | Address                              | POST Target                                                  |
|-------------+----------------+--------------------------------------+--------------------------------------------------------------|
| Both        | Lead Ingestion | 47064e037e5740bbedad@cloudmailin.net | https://staging.druidsite.com/api/v1/leads.json?token=XXX    |
| Staging     | Messages       | 1b524cb3122f466ecc5a@cloudmailin.net | https://staging.druidsite.com/api/v1/messages.json?token=XXX |
| Production  | Messages       | Unconfigured                         | Unconfigured                                                 |
|-------------+----------------+--------------------------------------+--------------------------------------------------------------|
```

### Twilio

Twilio provides outgoing and incoming SMS messaging for the Lead Messaging feature.

 * Outgoing SMS messages utilize the Twilio API.
 * Incoming SMS messages are ingested using a webhook.

#### Druid Configuration

The callback token can be viewed and reset at `LeadSource#Show`.

```
# Environment Variables
MESSAGE_DELIVERY_TWILIO_PHONE=+15126437241
MESSAGE_DELIVERY_TWILIO_SID=XXX
MESSAGE_DELIVERY_TWILIO_TOKEN=XXX
```

#### Twilio Configuration

Twilio configuration is performed at https://www.twilio.com. A master account
provisions sub-accounts for management.

```
|-------------+-----------+--------------+---------------------------------------------------------|
| Environment | Feature   | Phone Number | Callback                                                |
|-------------+-----------+--------------+---------------------------------------------------------|
| Staging     | Messaging | 512-643-7241 | https://staging.druidsite.com/api/v1/messages?token=XXX |
| Production  | Messaging | Unconfigured | Unconfigured                                            |
|-------------+-----------+--------------+---------------------------------------------------------|
```
