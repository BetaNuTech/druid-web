# Yardi Resident Check

Bluesky must never send a current Yardi resident into Yardi as a guest card.
This document covers the two halves of that rule: the push-time gate every
guest card path runs through, and the local residents import that the
creation-time checks read.

Code: `Leads::YardiResidentGate` (`app/lib/leads/yardi_resident_gate.rb`),
`Yardi::Backup::Database#residents_by_contact` / `#residents`
(`app/lib/yardi/backup/database.rb`), `Residents::Adapters::YardiBackup`
(`app/lib/residents/adapters/yardi_backup.rb`).

## Who counts as a resident

Yardi keeps a household as several rows:

| Row | Where | Contact details |
| --- | --- | --- |
| Primary tenant | `TENANT` (`ISTATUS` 0 current, 2 future, 3 eviction, 4 notice; 1 past) | `SPHONENUM0-9`, `SEMAIL` |
| The primary's own card | `PROSPECT` where `hMy = TENANT.hProspect` | `sTelCell/Home/Alt/Office`, `sEmail` |
| Household members | `PROSPECT` where `hParent = TENANT.hProspect` | same columns; `sRelationship` is Roommate, Spouse, Guarantor, Other, or blank (Occupant) |

Only statuses 0, 2, 3 and 4 count for the gate. Past tenants calling again are
prospects. Members whose own `sStatus` starts with `Cancel` are ignored.
`hProspect`/`hParent` are 0 when unset, so every join on them carries `> 0`.

Matching is on phone (any of the columns above, any format, exact 10 digits)
or email (case-insensitive). Placeholder values (`Lead::DUPLICATE_IGNORED_VALUES`)
and the property's own phone numbers never match.

**Guarantors** only count when the lead's last name matches too: a parent
guaranteeing a child's lease is a legitimate prospect for a unit of their own.

## Push-time gate (`Leads::YardiResidentGate`)

Every path that creates a guest card screens its leads against the Yardi
backup first, in the scheduled task, never in a web request:

| Path | Where | Residents in open/prospect | Matches in other states |
| --- | --- | --- | --- |
| Legacy sync (`leads:yardi:send_guestcards`, every 10 min) | `Leads::Adapters::YardiVoyager#createGuestCards` | invalidated as resident, memo "Yardi sync: matches Yardi resident ..." | one system note, not sent; re-screened next run |
| Self-booked tour push | `Leads::TourGuestcardPusher#push_property` | invalidated, memo "Self-booked tour push: ..." | same |
| Call lead push | `Leads::CallGuestcardPusher` (status `resident`) | invalidated | n/a (call leads are open) |

Invalidation is only allowed from open or prospect (`Leads::StateMachine`), so
a lead an agent has moved to showing or application is held with a note and
left alone. `new_leads_for_sync` and the tour candidates exclude leads
classified `resident`, NULL-safely (most leads have no classification).

One gate serves a whole rake run: the backup connection is opened on the first
screen that has leads (most runs have none) and reused for later properties
and for the call push (`gate.shared_database`).

### When the backup cannot be read

The backup restores a log every 30 minutes, at about :29 and :59 UTC, and is
briefly unreadable then; the 10-minute task's :00 and :30 runs can land in
that window. `Yardi::Backup::Database.open` retries 3 times, 20 seconds apart,
and then raises `Yardi::Backup::Database::Unavailable`. On that:

- the legacy sync holds the property's creates (updates and cancels of
  existing cards still run) and remembers the hold in `Rails.cache`
  (`leads:yardi:create_hold_since:<property id>`), so the next run widens its
  window back to the held run's start instead of losing the leads;
- the tour push reports the property as `error` with `pending` leads;
- the call push returns `skipped` and posts nothing, unless the oldest queued
  call has waited more than 3 hours.

Other backup errors (bad credentials, network) also hold the creates and do
post to #bluesky-errors.

## Creation-time checks and the local residents table

`Leads::Creator` (every lead source) rejects leads that match
`Leads::ResidentValidator`, and `Leads::Duplicates#invalidate_if_resident`
closes open leads that match `Lead.open_possible_residents`. Both read the
local `residents`/`resident_details` tables, comparing either lead phone with
either resident phone, email case-insensitively, with the same guarantor rule.

`rake residents:yardi:import` fills those tables from the Yardi backup
(`Residents::Adapters::YardiBackup`), hourly at :10 via Heroku Scheduler:

- primary tenants keep `residentid` = Yardi tenant code (`t0225446`), the same
  code the old SOAP import stored, so rows update in place;
- household members get their own row, `residentid` = `<tenant code>-<prospect code>`
  (`t0225446-p0523236`; ProspectIDs alone are not unique), the tenant's status
  and unit, and `relationship`;
- `status` is current (ISTATUS 0/2/3/4) or former (1); `yardi_status` keeps
  the Yardi word;
- `phone1`/`phone2` are the first two distinct numbers (own card first, then
  the tenant's phone fields), minus the property's own numbers; `email` is
  lower-cased;
- names, status, relationship, unit and contacts are the only fields written:
  `lead_id` (set by `Leads::ResidentProcessor`/`Residents::LeadMatcher`) and
  the address fields are left as they are;
- residents of the property Yardi no longer lists are set to former, except
  manually entered ones (`R` + 8 digits). The roommate rows the SOAP import
  created (`r0023191`) become former on the first run and are replaced by the
  member rows above;
- **safety valve:** if the listing is empty or lists fewer than half the
  current residents Bluesky already has, nothing is changed for that property
  and the run reports `WARN`.

Without the backup credentials (staging), the task falls back to the SOAP
import (`Residents::Adapters::YardiVoyager`).

```bash
# preview one property, change nothing
heroku run -a druid-prod rake residents:yardi:import PROPERTY=1002edge DRY_RUN=true
```

## The block log

Every refusal is recorded by `Leads::ResidentBlockLog` in two places:

- a system note on the property, shown under **Resident Blocks** on the
  property page (latest 20), and
- one line in Slack, posted as Yoda Bot to the channel named by
  `RESIDENT_BLOCK_SLACK_CHANNEL` (`#bluesky-resident-blocks` on production;
  unset means no Slack line). `YodaBotMessageJob` posts it from the
  `low_priority` queue with no link names, so caller data can never ping anyone.

Each line reads like `Vintage Edge: BlueConnect call to (615) 555-0100
(Google Business Profile), from (256) 263-6836, rejected on arrival, matches
resident Zoe Ellis, unit 0406, notice (Tenant t0225446)`. The "to" part is the
marketing source the lead's referral names, with its tracking number when the
source has one. The stages are `rejected on arrival` (no lead was created),
`closed after creation` (the automatic check invalidated a lead seconds after
it was saved), `closed before the Yardi push` (the gate or the call push
invalidated it) and `held before the Yardi push` (left to its agent, not sent).

## Checking a phone by hand

```ruby
Yardi::Backup::Database.open do |db|
  db.residents_by_contact('1002edge', phones: ['2562636836'], emails: ['zoe@example.com'])
end
# => { "2562636836" => [#<struct Resident tenant_code="t0225446", status="notice", relationship="Tenant", ...>] }
```

## Background

Vintage Edge, 2026-10-06: a resident on notice (Zoe Ellis) called the
property. Bluesky's call lead was invalidated as a resident within seconds by
the local table and the call push recorded `skipped_not_open`; the guest card
that appeared in Yardi was created by Lea AI (`leapro`) while answering the
call, not by Bluesky. The review that followed found the gaps this document
closes: household members were invisible to the backup check (their phones are
on `PROSPECT` rows, not `TENANT`), the legacy sync and tour push had no Yardi
resident check, and the daily SOAP import carried only primary tenants with
two phones each.
