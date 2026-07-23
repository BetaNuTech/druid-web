# Yardi Marketing Source Audit

## Why

Phone-call leads are attributed in Yardi Voyager via the GuestCard
`TransactionSource` element, which BlueSky populates from `lead.referral`
(see `Yardi::Voyager::Data::GuestCard.to_xml_1/to_xml_2` and
`GuestCardEvent`). For call-center leads, `referral` is the name of the
`MarketingSource` whose `tracking_number` matches the dialed number.

Voyager only accepts `TransactionSource` values that exactly match a
marketing source name configured in Voyager for that property. When the
name is unknown, `GuestCards#sendGuestCard` retries with the fallback
source `Bluesky`, losing attribution.

This audit verifies — per property — that every BlueSky `MarketingSource`
with a tracking phone number has an **exact, 1:1** name match in Voyager.

## How it works

- `Yardi::Voyager::Api::GuestCards#getMarketingSources(propertyid)` calls
  the Voyager SOAP method `GetYardiAgentsSourcesResults_Login` and returns
  the list of `SourceName` values for the property.
- `MarketingSources::YardiSourceAudit#audit_property(property)` is the
  single shared entrypoint (used by all triggers). It fetches Voyager's
  source names with retry (3 attempts, backoff), then updates
  `marketing_sources.yardi_source_missing` and
  `marketing_sources.yardi_source_checked_at` for all of the property's
  marketing sources. On API failure it leaves prior flags untouched and
  records an error Note.
- Sources without a tracking number are never flagged.

## Triggers

1. **On save:** `MarketingSource` `after_commit` enqueues
   `YardiSourceAuditJob` (delayed_job worker) for the property whenever a
   source with a tracking number is saved, or the tracking number is
   removed (to clear a stale flag).
2. **Daily:** Heroku Scheduler should run:

       rake marketing_sources:yardi_source_audit

3. **On deploy:** `bin/deploy` runs the same rake task after migrations
   for both staging and prod.

## Surfacing

Flagged sources show a red warning banner on the Marketing Sources page
(`app/views/marketing_sources/_marketing_source.html.erb`) with the last
checked timestamp. A property-scoped error Note is also created.
