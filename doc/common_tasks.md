# Common Bluesky Tasks

**Note that all of these instructions may be run in both development and production.**

# Leads

## Re-assigning Leads From Inactive Users

All "in-progress" leads may be reassigned from one user to another, specifying their email addresses. This will also reassign pending tasks for these leads. _Note that disqualified leads and leads that have progressed to resident status will not be modified._

`heroku run "rake leads:reassign[from_user@example.com,to_user@example.com]" --app druid-prod`

## Mass Disqualification

Bluesky does not provide a UI to perform large-scale edits or modification of Leads. These tasks should be performed using the Rails console.

It is highly suggested to trigger a new production database capture and load the production database into development for local testing before performing any mass changes. Document your commands before running them in production.

```
property = Property.active.where(name: "Peyton Stakes").first
time_window = 1.day.ago..
memo = "Mass disqualified because XXX REASON"
leads = Lead.where(property: property, created_at: time_window, state: :open);
puts "#{leads.count} Leads found"
leads.each{|lead| lead.transition_memo = memo; lead.classification = :lost; lead.trigger_event(event_name: 'disqualify')}
```

## Standardize Lead Sources

Agents often misspell Lead referral sources when entering manually. You may notice them in the Lead search UI. We have a task which standardizes known variations of Lead referral sources. Update the task at `lib/tasks/leads.rake` as needed to match the names of Marketing Sources.

`heroku run rake leads:referrals:standardize --app druid-prod`

## Reparse Recent "Null" Leads

Marketing sources often change their email formats, and the Lead email parser will fail to parse them. This results in the creation of Leads having "Null" as the first name. After the Lead parser is updated, it may be desired to retry ingestion of these Leads.

The following task will attempt to reparse Leads from the past month.

`heroku run rake leads:incoming:reparse --app druid-prod`

# Users

# Messages

## Retry Delivery

In the event of a service outage, failed delivery of outgoing messages and be retried using a rake task. Specify a time window before the current time in minutes.

`heroku run "rake messages:retry[1440]" --app druid-prod`

# System

## Display System "Notes"

System events are recorded in the `notes` table. You may list recent events using the following rake task.

The rake task options are `[hours,max_displayed]`:

`heroku run "rake notes:report[48,100]" --app druid-prod`

# Deployment Tasks

Any modifications of system data after a deployment are best documented and run in a consistent fashion.

Before deployment:
1. Add code for these tasks as a rake task in `lib/tasks/deployments.rake`
2. Trigger a database capture manually
3. Then run that task in production immediately afterward. `heroku run rake post_deployment:taskname --app druid-prod`
