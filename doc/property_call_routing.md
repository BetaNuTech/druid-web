# Property Call Routing Readiness

Everything a Property must have set for an incoming call to be routed and for
the resulting phone lead to be attributed. Implemented in
`Properties::CallRouting` (`app/models/concerns/properties/call_routing.rb`).

## The call path

1. A call comes in to a property main line or a marketing tracking number.
2. The call center asks `api/v1/leads#property_info`, which returns
   `Property.property_info_for_incoming_number`
   (`app/models/concerns/properties/marketing_sources.rb`).
3. It forwards the call using the numbers in that response.
4. If the caller becomes a lead, the call center posts it back with the
   `property_id` and `referrer` from that same response.
5. `Leads::Creator` resolves the property from that code and matches
   `lead.referral` to a MarketingSource by name.

## Blocking settings

Without these the call is not handled or the lead is not attributed.

### Main line (`Property#phone`)

The *Phone (Main Line)* field under Contact Information.

- A call placed directly to the property is resolved by
  `Property.active.where(phone: clean_number)`. No main line, no match.
- `main_number`, `leasing_number`, and `maintenance_number` in the response
  all fall back to `property.phone` when the leasing/maintenance numbers are
  blank. So a blank main line blanks all three at once, and a call to a
  tracking number has nowhere to forward.

Blank leasing and maintenance numbers are **fine and not flagged** — falling
back to the main line is the designed behavior. That fallback is precisely
why the main line itself is critical.

`MarketingSources::IncomingIntegrationHelper` also suggests `property.phone`
as the `destination_number` when setting up a tracking number.

### CallCenter property listing code

The `property_id` in the response is *not* the property UUID — it is the
`PropertyListing.code` for the **CallCenter** lead source. The call center
echoes it back on lead creation and `Leads::Creator#assign_property` resolves
it via `Property.find_by_code_and_source`, which requires **both the listing
and the lead source to be active**.

Missing or inactive → the lead is still created, but with no property: no
agent assignment, no engagement policy, only a warning note. It fails
silently after the call itself succeeded.

## Warnings

These degrade behavior but do not break the call or its attribution.

| Setting | Effect when unset |
| --- | --- |
| `timezone` | Defaults to `"UTC"` and is never blank, so nothing errors. The `open` flag and `hours` reported to the call center are several hours off. The property form's `time_zone_select` default never applies, because the column default means the value is never blank. |
| YardiVoyager listing code | `voyager_property_code` is blank, so guest cards cannot be pushed and `MarketingSources::YardiSourceAudit` skips the property — the Yardi source mismatch warning silently never runs. See [yardi_marketing_source_audit.md](yardi_marketing_source_audit.md). |
| `working_hours` | Only populates `hours` (a display string) and `open` in the response. It does not affect which number the call forwards to or the referrer used for attribution, and `office_open?` rescues to `true`. |

### The working_hours crash (fixed)

`office_hours_today` used to read `working_hours[today]['morning']['open']`
with no nil guard, and `property_info_for_incoming_number` calls it
unconditionally. The column has no DB default, so a property whose hours were
never set raised `NoMethodError` and **took down the whole endpoint** — no
destination number and no referrer for any call to that property. It now
falls back to `DEFAULT_WORKING_HOURS` and returns `'Closed'` rather than
raising.

## Where the warnings surface

Nothing blocks a save — an incomplete property must not prevent marketing
source setup — so gaps surface as warnings via
`Property#call_routing_issues`, rendered by
`app/views/shared/_call_routing_issues.html.erb`:

| Where | Shown when |
| --- | --- |
| Property edit form, top of page | Any issue on a persisted property. The Contact Information fieldset is collapsed by default, so help text alone would not be seen. |
| Property edit form, under the Phone field | Always; flagged when `main_line_missing?` |
| Property show page, Phone attribute | `main_line_missing?` |
| Marketing Sources index, once per property | The property has tracking numbers (`marketing_tracking_numbers?`) |
| Marketing Source form, Phone Tracking section | Any issue on the selected property |
| Flash after create/update of a marketing source | The source has a tracking number and the property has **blocking** issues (`MarketingSourcesController#call_routing_alert`) |

Per-source (not per-property) warnings, such as the Yardi source name
mismatch, stay on the individual marketing source card.

## Things that look load-bearing but are not

- `MarketingSource#destination_number` is stored and defaults to
  `property.phone` in the form, but is never sent anywhere. The actual
  forwarding targets are the property's main/leasing/maintenance numbers.
- `Property#call_lead_generation` ("Generate Leads from Incoming Calls" on the
  preferences form) — its scope `supporting_call_lead_generation` has no
  callers anywhere in the app.
- `Property#referral_name_for_incoming_number` has no callers; the referrer
  comes from the `referrer` key of the property_info response instead.
- The tracking-number lookup in `property_info_for_incoming_number` applies no
  `active`/`current` scope to either the marketing source or the property,
  while the main-line lookup requires `Property.active`.
