# Bluesky Third Party Services

TODO

# Application Hosting

The Bluesky staging and production environments are hosted using the Heroku.com PaaS.

Both the applications and databases are served using Heroku's services.

`https://dashboard.heroku.com/apps`

# Domains

* Staging: `staging.druidsite.com`
* Production: `www.blue-sky.app` and `www.druidsite.com`

## SSL

The SSL certificates are automatically managed by Heroku

# Heroku

## Runtime Environments

* Staging: `druid-staging`
* Production: `druid-prod`

### Buildpacks

The following buildpacks are necessary for operation.

* `heroku/nodejs`
* `heroku/ruby`

### Processes

* 2x Web - Puma
* 2x Worker - Rails ActionJob worker backed by PostgreSQL

( See Procfile )

### Add-ons

Heroku addons provide all of the essential services used by the application:

#### Critical Services
* Database - Heroku Postgres (Plans - Staging: `Basic`, Production: `Standard-0`)
* Cache - Memcached - MemCachier (Staging: `developer`, Production: `developer`)

#### Necessary Services
* SMTP Outgoing Email - Mailgun (Staging: `Concept 50k`, Production: `Concept-50`)
* Scheduled Workers - Heroku Scheduler

#### Optional Services
* Logging - Papertrail (Staging: `Choklad`, Production: `Ludvig`)
* Performance Metrics - Newrelic APM (Production: `Wayne`)

#### Configuration

See ENV's prefixed with `MAILGUN_` and `PAPERTRAIL_`:

* `MAILGUN_API_KEY`
* `MAILGUN_DOMAIN`
* `MAILGUN_PUBLIC_KEY`
* `MAILGUN_SMTP_LOGIN`
* `MAILGUN_SMTP_PASSWORD`
* `MAILGUN_SMTP_PORT`
* `MAILGUN_SMTP_SERVER`
* `PAPERTRAIL_API_TOKEN`

### Scheduled Jobs

The following rake tasks are run at specified times.
(Daily run times are somewhat arbitrary and changes should not cause operational issues.)

* `rake cache:warm:all` 	Hourly at :20
* `rake health:services:cloudmailin` 	Hourly at :10
* `rake leads:auto_lodge` 	Daily at 4:00 PM UTC
* `rake leads:prioritize` 	Daily at 7:00 AM UTC
* `rake leads:process_followups` 	Daily at 4:30 PM UTC
* `rake leads:resident_auto_transition` 	Daily at 11:00 AM UTC
* `rake leads:waitlist:process` 	Daily at 6:00 AM UTC
* `rake leads:yardi:send_guestcards[20]` 	Every 10 minutes
* `rake marketing_expenses:create_pending` 	Daily at 3:00 PM UTC
* `rake messages:fix_notifications` 	Every 10 minutes
* `rake messages:retry[1440]` 	Hourly at :40
* `rake residents:yardi:import` 	Daily at 11:00 PM UTC
* `rake statistics:generate statistics:rollup` 	Hourly at :40
* `rake unit_types:yardi:import_floorplans units:yardi:import_units`  Hourly at :20
* `rake users:task_reminders` 	Daily at 11:00 PM UTC

### Deployment

Esssentially, Heroku deployment is accomplished using git. For more information see: `https://devcenter.heroku.com/articles/git` and `README.md`

For convenience, the script at `bin/deploy` will create a git tag, push code to Heroku, and run any pending database migrations.

```
# Usage and Example deployment process:
git checkout staging && git merge master && git push
bin/deploy staging
git checkout production && git merge master && git push
bin/deploy prod
```

### Maintenance Notes

* Heroku manages SSL and hosting, minimizing Ops overhead.
* The application stack for Bluesky is pending upgrade from `heroku-20`

# Yardi Voyager

Yardi Voyager is the software used by Property management. It manages leads, residents, units, and more.

`https://www.yardiasp14.com`

Bluesky makes heavy use of data from Yardi Voyager. Yardi Voyager integration is important, but not absolutely necessary for the function of Bluesky.

There are multiple background tasks and other integrations that pull resident, unit, and lead information.

Bluesky is the source of truth for the incoming Lead pipeline, while Yardi is the source of truth for Resident and Unit information.

* See `app/lib/yardi` for general Yardi integration
* See `app/lib/leads/adapters/yardi_voyager.rb` for syncing leads between the applications and retrieving resident and unit information from Yardi.

#### Configuration

There are a number of ENV variables that are responsible for integration configuration. See ENV's prefixed by `YARDI_VOYAGER_`:

* `YARDI_VOYAGER_HOST="www.yardiasp14.com"`
* `YARDI_VOYAGER_LICENSE="XXX"`
* `YARDI_VOYAGER_SERVERNAME="gazv_live"`
* `YARDI_VOYAGER_DATABASE="gazv_live"`
* `YARDI_VOYAGER_WEBSHARE="21253beta"`
* `YARDI_VOYAGER_USERNAME="XXX"`
* `YARDI_VOYAGER_PASSWORD="XXX"`
* `YARDI_VOYAGER_VENDORNAME="Druid ILS Guest Card"`
* `YARDI_VOYAGER_REQUEST_SERVICE_HOST="www.yardiasp14.com"`
* `YARDI_VOYAGER_REQUEST_SERVICE_LICENSE="XXX"`
* `YARDI_VOYAGER_REQUEST_SERVICE_SERVERNAME="gazv_live"`
* `YARDI_VOYAGER_REQUEST_SERVICE_DATABASE="gazv_live"`
* `YARDI_VOYAGER_REQUEST_SERVICE_WEBSHARE="21253beta"`
* `YARDI_VOYAGER_REQUEST_SERVICE_USERNAME="XXX"`
* `YARDI_VOYAGER_REQUEST_SERVICE_PASSWORD="XXX"`
* `YARDI_VOYAGER_REQUEST_SERVICE_VENDORNAME="Sapphire Standard"`

# Cloudmailin

Cloudmailin is an incoming SMTP service managed independently of Heroku.

`https://www.cloudmailin.com/dashboard`

In response to emails sent to configured email addresses, Cloudmailin calls webhooks in Bluesky to provide Leads and incoming email messaging.

See `cloudmailin_incoming_leads.md` for more information # TODO


## Addresses

### Staging

* Incoming Messages: `2d69063f298d8f69f9bb@cloudmailin.net`
    * Webhook: `https://staging.druidsite.com/api/v1/messages.json?token=XXX` via HTTP POST
    * Free Plan

### Production

* Incoming Messages: `1b524cb3122f466ecc5a@cloudmailin.net`
    * Webhook: `https://www.blue-sky.app/api/v1/messages.json?token=XXX` via HTTP POST
    * Starter Plan
* Incoming Leads: `47064e037e5740bbedad@cloudmailin.net`
    * Webhook: `https://www.blue-sky.app/api/v1/leads.json?token=XXX` via HTTP POST
    * Professional Plan

## Configuration

Set the reply-to email address so that leads can reply to outgoing messages from agents using Bluesky.

* `MESSAGE_DELIVERY_REPLY_TO`=`1b524cb3122f466ecc5a@cloudmailin.net`

### Webhook Authentication

The `token` parameter of the webhook URL is configured by a `MessageDeliveryAdapter` record. These records must be maintained using the Rails console.

```
heroku run rails console --app druid-prod
# In production rails console
mda = MessageDeliveryAdapter.where(slug: 'CloudMailin').first
token = mda.api_token
# If you need to reset the token
mda.reset_api_token
```

# Twilio

SMS message and delivery in Bluesky uses the Twilio service.

`https://console.twilio.com/`

The Twilio API is used for outgoing SMS messages, while incoming SMS messages are ingested using a webhook.

The configuration for Twilio in Bluesky can be found in the following environment variables:

- `MESSAGE_DELIVERY_TWILIO_PHONE`: This variable contains the phone number used for outgoing SMS messages.
- `MESSAGE_DELIVERY_TWILIO_SID`: This variable contains the Twilio SID, which is a unique identifier for the Twilio account.
- `MESSAGE_DELIVERY_TWILIO_TOKEN`: This variable contains the Twilio token, which is used for authentication with the Twilio API.

Additionally, there is an environment variable called `MESSAGE_WHITELIST_ENABLED`. When set to 'true' or '1', this variable restricts the delivery of SMS and email messages to only user accounts registered in Bluesky. This is for testing and staging usage to prevent unintentional messaging of leads in non-production contexts.

## Outgoing

Outgoing

## Incoming

See `https://console.twilio.com/us1/develop/phone-numbers/manage/incoming` for phone number and callback configuration.

Incoming SMS messages from Twilio are processed using a webhook at `https://www.blue-sky.app/api/v1/messages?token=XXX`. The token is the `api_token` from the Twilio `MessageDeliveryAdapter` record (see the CloudMailin documentation above)

# Amazon AWS

## ActiveStorage

In staging and production we use ActiveStorage backed by Amazon S3 to store binary attachments.

### BlueSky Configuration

```
# Environment Variables
ACTIVESTORAGE_S3_BUCKET="druid-prod-activestorage"
ACTIVESTORAGE_S3_REGION="us-east-1"
ACTIVESTORAGE_S3_ACCESS_KEY="XXX"
ACTIVESTORAGE_S3_SECRET_KEY="XXX"
```

### Amazon Configuration

The S3 bucket is configured to block all public access.

The access key and secret are credentials assocated with the `druid-staging-activestorage` or `druid-prod-activestorage` IAM users.

Example Access Policy:

```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "s3:GetBucketLocation",
                "s3:ListBucketMultipartUploads"
            ],
            "Resource": "arn:aws:s3:::druid-staging-activestorage"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:AbortMultipartUpload",
                "s3:DeleteObject",
                "s3:DeleteObjectVersion",
                "s3:GetObject",
                "s3:GetObjectAcl",
                "s3:GetObjectVersion",
                "s3:GetObjectVersionAcl",
                "s3:PutObject",
                "s3:PutObjectAcl",
                "s3:PutObjectAclVersion"
            ],
            "Resource": "arn:aws:s3:::druid-staging-activestorage/*"
        }
    ]
}
```

## Blueconnect (AWS Callcenter)

"Blueconnect" is a service backed by AWS Callcenter and Lambda which routes marketing tracking phone numbers to property main office phones.

See `doc/incoming_lead_parser.md` for more information.
