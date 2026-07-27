# Self-Booked Tour Lead Guestcard Push (TEMPORARY)

**Status: temporary feature, expected to be disabled ~30 days after 2026-07-27.**

## Why

Self-booked tour leads (tour confirmation emails classified by the OpenAI
parser as `lead_type: tour_booking`) are intentionally left in the `open`
state and unassigned so an agent can pick them up
(`ProcessCloudmailinEmailJob`). The standard Yardi sync
(`Properties::YardiVoyager#new_leads_for_sync`) only pushes open leads that
have an assigned user, so these leads never became Voyager guestcards.

A one-off backfill on 2026-07-23 pushed/linked 172 of them. Self-booked
tours will continue to arrive this way for roughly 30 more days, so
`Leads::TourGuestcardPusher` repeats the same procedure on a schedule.

## What it does

For every active property with a Voyager code, for each open lead with a
blank `remoteid` and a "Tour Booking detected" system note:

1. **Dedup:** searches Yardi by email/phone (`findLeadGuestCard`). If a
   guestcard exists, links its prospect ID to `lead.remoteid` (no create).
   If the search fails, the lead is skipped and retried next run.
2. **Attribution:** forces `referral` (and therefore the Yardi
   `TransactionSource`) to `Property Website`, with an audit Note when the
   original value differed.
3. **Create:** sends the guestcard with:
   - a round-robin agent from Voyager's **active** agent roster for the
     property (`GuestCards#getAgents`), excluding system entries
     (Portal, Admin, Lea-Lite, Lea-Pro — Admin would activate Lea AI)
   - a FirstContact event dated with the lead's original arrival
     (`none -> open` transition), so it counts retroactively
   - an event comment "Self-booked tour lead." plus the tour details from
     the lead's preference notes
4. Leads remain open and unassigned in BlueSky; the saved `remoteid`
   prevents the nightly sync from re-creating them.

Runs are serialized with a Postgres advisory lock so overlapping scheduler
dynos cannot double-create guestcards.

## Triggers

- **Every 10 minutes** via Heroku Scheduler:

      rake leads:push_tour_guestcards

- Gated by the env var `TOUR_GUESTCARD_PUSH_ENABLED` (default `false`).
  The task exits immediately with a skip message when unset/false.
- Supports `DRY_RUN=true` (read-only preview, performs Yardi searches but
  writes nothing).

## Enable / disable

    # enable
    heroku config:set TOUR_GUESTCARD_PUSH_ENABLED=true -a druid-prod

    # disable (kill switch)
    heroku config:unset TOUR_GUESTCARD_PUSH_ENABLED -a druid-prod

To retire the feature permanently, also remove the Heroku Scheduler entry.
