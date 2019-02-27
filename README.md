# README

This is the Druid Web Application created by and for BlueStone Properties.

# License

Copyright 2017-2018 BlueStone Properties
This code is proprietary and distribution is strictly prohibited.

# Dependencies

* Ruby version: 2.4.3 (in Gemfile)
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
  * Customize `.env` from `env.example`
  * Customize `.pryrc` from `pryrc.example`
  * ... etc. as indicated by `bin/setup`

Any configuration that is used in production should use environment variables instead of config files.
Config files in this application should be created VERY SPARINGLY and NEVER include secrets. The purpose of
these default configuration files

Whenever a new config file MUST be created, be sure to:
  * create a `.example` file
  * update `bin/setup`
  * add the config file to `.gitignore`
  * we do not want to create configuration files intended only for development/developers to be checked into source control

### CDR Database

Setup of the Asterisk Call Data Record database is not performed by `bin/setup`.

In production, this database is a replica MySQL instance. In development, it is best to load a database
dump into a local instance.

Example development setup would look like this:

```
mysql -e 'create database asteriskcdrdb; grant all privileges on asteriskcdrdb.* to 'cdrdb'@'localhost' identified by 'cdrdb_Password';"
mysql asteriskcdrdb < db/cdrdb-schema.sql
# OR
mysql asteriskcdrdb < path/to/cdrdb-dump.sql
```

And add the `CDRDB_URL` environment variable to `.env`:

```
CDRDB_URL='mysql2://cdrdb:cdrdb_Password@localhost/asteriskcdrdb'
```

#### CDR Recordings

Call recordings in WAV format are synchronized from the Asterisk phone system to an S3 bucket on Amazon.

Integration with this S3 bucket requires the following environment variables to be set:

```
CDRDB_S3_BUCKET='druidaudio'
CDRDB_S3_REGION='us-east-2'
CDRDB_S3_ACCESS_KEY=XXX
CDRDB_S3_SECRET_KEY=XXX
```

#### Determine CDR Recording Bucket Usage

A helpful script at `bin/bucket_size` can be used to determine S3 bucket usage. This tool requires the `awscli` tools to be installed, and configuration placed in `~/.aws/credentials`

```
# ~/.aws/credentials

[asterisk-druidaudio]
aws_access_key_id = XXX
aws_secret_access_key = XXX
region = us-east-2
```

The following environment variables must be set in `.env`:

```
CDRDB_S3_BUCKET='druidaudio'
CDRDB_AWSCLI_PROFILE='asterisk-druidaudio'
```

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
  * Corporate: Corporate Staff
  * Manager: sales agent manager
  * Agent: sales agents with limit management access

### UI

Admins (Role is `administrator` or `operator`) may manage users via a Web UI.

# Production/Staging

## General Configuration

### Environment Variables

Reference `env.example` for the full set of required environment variables. Values WILL
vary from what is shown below.

```
# Environment Variables
ACTIVESTORAGE_S3_BUCKET
ACTIVESTORAGE_S3_REGION
ACTIVESTORAGE_S3_ACCESS_KEY
ACTIVESTORAGE_S3_SECRET_KEY
APPLICATION_HOST=www.druidapp.com
CDRDB_S3_ACCESS_KEY=''
CDRDB_S3_BUCKET='druidaudio'
CDRDB_S3_REGION='us-east-2'
CDRDB_AWSCLI_PROFILE='asterisk-druidaudio'
CDRDB_S3_SECRET_KEY=''
CDRDB_URL='mysql2://USERNAME:PASSWORD@asterisk-druid.ckdn2rnrfzse.us-east-2.rds.amazonaws.com/asteriskcdrdb?sslca=config/amazon-rds-ca-cert.pem'
CRYPTO_KEY=XXX
DEBUG_MESSAGE_API=false
EXCEPTION_NOTIFIER_ENABLED=true
EXCEPTION_RECIPIENTS='example@example.com,example2@example.com'
HTTP_AUTH_NAME=XXX
HTTP_AUTH_PASSWORD=XXX
LANG=en_US.UTF-8
MAILGUN_API_KEY=XXX
MAILGUN_DOMAIN=XXX
MAILGUN_PUBLIC_KEY=XXX
MAILGUN_SMTP_LOGIN=XXX
MAILGUN_SMTP_PASSWORD=XXX
MAILGUN_SMTP_PORT=XXX
MAILGUN_SMTP_SERVER=XXX
MEMCACHE_SERVERS=localhost
MEMCACHIER_SERVERS=XXX (production only)
MEMCACHIER_USERNAME=XXX (production only)
MEMCACHIER_PASSWORD=XXX (production only)
MESSAGE_DELIVERY_REPLY_TO="messages@example.com"
MESSAGE_DELIVERY_TWILIO_PHONE='+15555555555'
MESSAGE_DELIVERY_TWILIO_SID='XXX'
MESSAGE_DELIVERY_TWILIO_TOKEN='XXX'
MESSAGE_WHITELIST_ENABLED='false'
PAPERTRAIL_API_TOKEN=XXX
PORT=3000
RACK_ENV=production
RAILS_ENV=production
RAILS_LOG_TO_STDOUT=enabled
RAILS_MAX_THREADS=5
RAILS_SERVE_STATIC_FILES=enabled
SCOUT_DEV_TRACE=true
SCOUT_KEY=XXX
SCOUT_LOG_LEVEL=WARN
SCOUT_MONITOR=false
SECRET_KEY_BASE=XXX
SMTP_DOMAIN=localhost
WEB_CONCURRENCY=1
YARDI_VOYAGER_DATABASE="gazv_test"
YARDI_VOYAGER_HOST="www.yardiasp14.com"
YARDI_VOYAGER_LICENSE="XXX"
YARDI_VOYAGER_PASSWORD="XXX"
YARDI_VOYAGER_SERVERNAME="gazv_test"
YARDI_VOYAGER_USERNAME="XXX"
YARDI_VOYAGER_VENDORNAME="Bluestone Druid"
YARDI_VOYAGER_WEBSHARE="21253beta"
```

### Seed Data

After the application has been provisioned and deployed and the addons setup, seed the application data.

```
heroku run --app APPNAME rake db:schema:load
heroku run --app APPNAME rake db:seed
```

Immediately login as `admin@example.com` using the password `ChangeMeNow`, then update the admin account to use a secure password. Then change the admin email address. Delete the `agent@example.com` account afterwards.

## Services

### Cache

Memcached is used for `ActiveSupport::Cache::Store`

#### Druid Configuration

```
# Environment Variables
MEMCACHE_SERVERS=XXX (automatically set by addon configuration)
```

### Messaging (General)

Delivery of SMS and email messages can be restricted to numbers and email addresses of registered users using the `MESSAGE_WHITELIST_ENABLED` environment flag.
Set this variable to `1` or `true` to prevent messages from being sent to leads.

### PostgreSQL

PostgreSQL is the primary relational database, used by ActiveRecord.

On Heroku, this service is provisioned as an addon using the 'standard-0' tier.

#### Druid Configuration

```
# Environment Variables
DATABASE_URL=XXX (automatically set by addon configuration)
```

### Asterisk CDR Database

In production, the Asterisk CDR database is a replicated MySQL database containing call records. This database backs the `Cdr` ActiveRecord model.

A schema SQL file is provided in `db/cdrdb-schema.sql`

Heroku requires special configuration in order to contact Amazon RDS database hosts:
A custom CA certificate is required. (see: https://devcenter.heroku.com/articles/amazon-rds)

This CA certificate was downloaded and committed to SCM:

```
curl https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem > ./config/amazon-rds-ca-cert.pem
```

This problem can identified in logs with the following error message:

```
Mysql2::Error::ConnectionError: Can't connect to MySQL server on 'asterisk-druid.ckdn2rnrfzse.us-east-2.rds.amazonaws.com'
```

#### Druid Configuration

# Environment Variables
The `CDRDB_URL` for production should look like this:

```
CDRDB_URL='mysql2://USERNAME:PASSWORD@asterisk-druid.ckdn2rnrfzse.us-east-2.rds.amazonaws.com/asteriskcdrdb?sslca=config/amazon-rds-ca-cert.pem'
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

### ActiveStorage

In staging and production we use ActiveStorage backed by Amazon S3 to store binary attachments.

#### Druid Configuration

```
# Environment Variables
ACTIVESTORAGE_S3_BUCKET="druid-prod-activestorage"
ACTIVESTORAGE_S3_REGION="us-east-2"
ACTIVESTORAGE_S3_ACCESS_KEY="XXX"
ACTIVESTORAGE_S3_SECRET_KEY="XXX"
```

#### Amazon Configuration

The access key and secret are credentials assocated with the `druid-staging-activestorage` or `druid-prod-activestorage` IAM users.

Example Access Policy:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DruidActiveStorage",
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::druid-prod-activestorage"
            ]
        }
    ]
}
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
|-------------+----------------+--------------------------------------+----------------------------------------------------------|
| Environment | Feature        | Address                              | POST Target                                              |
|-------------+----------------+--------------------------------------+----------------------------------------------------------|
| Production  | Lead Ingestion | 47064e037e5740bbedad@cloudmailin.net | https://www.druidsite.com/api/v1/leads.json?token=XXX    |
| Staging     | Lead Ingestion | Unconfigured                         | Unconfigured                                             |
| Production  | Messages       | 1b524cb3122f466ecc5a@cloudmailin.net | https://www.druidsite.com/api/v1/messages.json?token=XXX |
| Staging     | Messages       | Unconfigured                         | Unconfigured                                             |
|-------------+----------------+--------------------------------------+----------------------------------------------------------|

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
MESSAGE_WHITELIST_ENABLED='false'
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

### Exception Notification

The `exception_notification` gem is used to email error notifications to developers.

The `ErrorNotification` class is exposed to allow easy notification of errors from anywhere:

Usage: `ErrorNotification.send(StandardError.new('error message'), {extra1: 'foo', extra2: 'bar'})`

#### Druid Configuration

```
# Environment Variables
EXCEPTION_RECIPIENTS='example@example.com,example2@example.com' # Required or notification gracefully fails
EXCEPTION_NOTIFIER_ENABLED=true   # Enabled by default
```

### CircleCI

Automated tests are performed by CircleCI.

#### Configuration

See `.circleci/config.yml` for configuration.

#### Local Testing

Test build using:

```
circleci local execute --job build
```


## Scheduled Tasks

The Heroku Scheduler should be configured to run the following tasks

```
|-----------+-------------------------------------+-------------------------------------------------------------|
| Frequency | Task                                | Description                                                 |
|-----------+-------------------------------------+-------------------------------------------------------------|
| 10m       | rake leads:calls:generate_leads[60] | Generate leads from incoming calls in the past 60 minutes   |
| 10m       | rake leads:yardi:send_guestcards    | Send claimed Leads to Yardi Voyager                         |
| Hourly    | rake leads:yardi:import_guestcards  | Fetch Yardi Voyager Guestcards as Leads                     |
| Daily     | rake leads:recordings:cleanup       | Delete calll recordings >2wks old not associated with leads |
|-----------+-------------------------------------+-------------------------------------------------------------|
```

