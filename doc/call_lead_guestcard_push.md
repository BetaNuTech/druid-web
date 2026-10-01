# Call Lead → Yardi Guest Card Push

Every BlueConnect call to a property's marketing number becomes a Bluesky lead
(LeadSource `CallCenter`). Leasing works in Yardi, not Bluesky. This feature
makes sure each new caller ends up in Yardi as a guest card that Lea AI picks
up, without duplicating a card that already exists.

Code: `Leads::CallGuestcardPusher` (`app/lib/leads/call_guestcard_pusher.rb`),
`Leads::CallGuestcards` (Lead concern), `CallGuestcardPush` (model),
`Yardi::Backup::Database` and `Yardi::Backup::SocksTunnel` (`app/lib/yardi/backup/`).

## Why it exists (October 2026)

- Bluesky only ever pushed a call lead to Yardi after an agent claimed it in
  Bluesky. Agents stopped working in Bluesky in late May 2026, so no call lead
  has reached Yardi since then.
- A match of the last 30 days of calls against Yardi found 34% of callers had
  no guest card at all, 9% got one around the time of the call (mostly
  Lea AI's), and 56% already had one. About 38% of all callers are current
  residents.
- Voyager's SOAP guest card search missed 9 of 10 cards that exist, so it
  cannot be used to check for duplicates. The Yardi backup database is used
  instead.

## Settings

| Variable | Default | Purpose |
| --- | --- | --- |
| `CALL_LEAD_GUESTCARD_PUSH_ENABLED` | off | **The switch.** `true` turns the whole feature on. |
| `YARDI_BACKUP_DB_HOST`, `_PORT` (1433), `_NAME`, `_USER`, `_PASS` | – | Yardi backup database. Same names and values as Cobalt2. |
| `YARDI_SOCKS_PROXY` (or the Fixie add-on's `FIXIE_SOCKS_HOST`) | – | SOCKS5 proxy whose static IPs the backup server's firewall allows. Same as Cobalt2. |
| `CALL_LEAD_GUESTCARD_HOLD_MINUTES` | 15 | How long after a call before Bluesky decides (see Timing). |
| `CALL_LEAD_GUESTCARD_FIX_SOURCE_ENABLED` | off | Correct the source on Lea AI's card for a call. Unverified; see below. |
| `YARDI_BACKUP_SOURCE_TIME_ZONE` | America/New_York | Time zone of Yardi's backup history timestamps. |

No extra Heroku Scheduler entry is needed: the pusher runs at the end of
`leads:yardi:send_guestcards`, which is already scheduled every 10 minutes.

## What happens while it is on

1. **On create**, a call lead for a property with a Voyager code is queued
   (`CallGuestcardPush`, status `pending`). Only leads created while the
   switch is on are queued.
2. **No automated outreach**: Bluesky sends the caller no SMS opt-in request
   and no welcome email (`Lead#automated_outreach_suppressed?`). An agent
   explicitly forcing an opt-in request still works.
3. **Every 10 minutes**, queued leads whose call is covered by the backup are
   resolved. Each ends in one status:

| Status | When | Bluesky lead | Yardi |
| --- | --- | --- | --- |
| `created` | no card for that phone at the property | system user, prospect, `remoteid` set | **new guest card, agent Admin** (Lea AI picks it up), source = the call's marketing source |
| `linked_new_card` | a card was made for this call (Lea AI's, created up to 30 min before the lead) | system user, prospect, linked | source corrected if enabled; otherwise untouched |
| `linked_existing_card` | the caller already had a card | system user, prospect, linked | untouched (first-touch source kept) |
| `repeat_call` | the same caller was resolved here within 48h | invalidated as duplicate | nothing |
| `resident` | phone matches a current, future, notice or eviction tenant | invalidated as resident | nothing |
| `skipped_not_open` | Bluesky had already closed the lead (its own dedupe) | unchanged | nothing |
| `failed` | 5 failed attempts | open, error note | – |

Matching is by phone (all four PROSPECT phone fields, any format) at the same
property. A canceled card still counts as existing: the call is linked, not
re-created, and the card is not reopened.

## Timing

The backup is a log-shipped copy: Yardi takes a log backup every 30 minutes
and it is restored about 29 minutes later, so its data is 30–60 minutes behind.
`Yardi::Backup::Database#data_as_of` reads the exact point in time from the
backup history. A queued lead is only resolved once that time is past the call
plus the hold, so any card Lea AI made while answering the call is visible
first. **Expect a new Admin card roughly 45–75 minutes after the call.**
Cards the pusher itself created are matched from Bluesky's own records until
the backup catches up, so repeat callers never get a second card.

A retry after a failed push also waits until the backup covers the failed
attempt, in case Yardi created the card but the response was lost.

If the backup falls more than 3 hours behind (log shipping stopped), queued
leads wait and an error posts to #bluesky-errors.

## Bluesky's other Yardi sync

The legacy sync (`Properties::YardiVoyager#new_leads_for_sync`,
`#leads_for_sync`, `#leads_for_cancelling`, and the
`leads:yardi:fix_future_invalidated_types` task) skips every lead in
`CallGuestcardPush::YARDI_OWNED_STATUSES`. It never creates a second card,
overwrites the agent on a card Lea AI or an agent owns, or cancels it. This
holds even after the switch is turned off. Leads that were never resolved
(pending, failed or skipped) sync normally.

## Attribution correction (off until verified)

Lea AI records every call card's source as "Property Website". With
`CALL_LEAD_GUESTCARD_FIX_SOURCE_ENABLED=true`, a `linked_new_card` card that is
still in Prospect status and has a different source gets a minimal
`ImportYardiGuest` update. It carries only the card's own identity plus one
first-contact event with the call's source
(`Yardi::Voyager::Api::GuestCards#sendSourceCorrection`). Canceled cards are
skipped, because re-stating them could reopen them.

Whether Voyager actually changes `PROSPECT.sSource` this way is **not yet
verified**. Test it on one lead first:

```bash
heroku run -a druid-prod rake "leads:call_guestcards:fix_source[LEAD_ID]"
```

After the next backup restore, confirm that card's `sSource` changed, then turn
on the setting. Every `linked_new_card` push records the card's original source
in `yardi_source`, so earlier calls can be corrected later.

## Running and monitoring

```bash
heroku run -a druid-prod rake leads:push_call_guestcards DRY_RUN=true
```

```ruby
CallGuestcardPush.group(:status).count
CallGuestcardPush.pending.joins(:lead).minimum('leads.created_at')  # oldest waiting call
CallGuestcardPush.where(status: 'failed').pluck(:lead_id, :last_error)
```

## Not done yet

- **Backfill**: calls from before the switch was turned on are not queued.
  Pushing the missing cards for the previous 30 days is a separate, approved
  follow-up (it can queue `CallGuestcardPush` rows for those leads and run the
  pusher with `DRY_RUN=true` first).
- Calls to numbers Bluesky does not know about (see
  [property_call_routing.md](property_call_routing.md)) arrive without a
  property and are not queued.

## Technical notes

- `tiny_tds` (FreeTDS) talks to SQL Server. Heroku installs the precompiled
  `x86_64-linux` gem, which bundles FreeTDS, so `Gemfile.lock` lists that
  platform. Locally, run `brew install freetds`.
- FreeTDS cannot use a SOCKS proxy, so `SocksTunnel` opens a local port and
  relays it through the proxy. The relay runs in a **forked child process**:
  tiny_tds holds Ruby's global VM lock while it logs in, so relay threads in
  the same process would never run.
- The decision logic is `Leads::CallGuestcardPusher.decide`. Replaying the
  last 30 days of real calls through it predicted about 4.5 new Admin cards a
  day across the three properties, 152 resident calls closed, and 86 repeat
  calls closed.
