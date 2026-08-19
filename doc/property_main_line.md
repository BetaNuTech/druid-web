# Property Main Line (Property#phone)

## What it is

The "main line" is the `phone` column on `Property` — the *Phone (Main Line)*
field under Contact Information on the property edit form.

## Why it matters for phone lead attribution

`Property.property_info_for_incoming_number` (`app/models/concerns/properties/marketing_sources.rb`)
is what the call routing integration hits for every incoming call
(`api/v1/leads` → `property_info`). Two things there depend on the main line:

1. A call placed directly to the property is resolved by
   `Property.active.where(phone: clean_number)`. With no main line, that lookup
   never matches.
2. For a call placed to a marketing tracking number, the response's
   `main_number`, `leasing_number`, and `maintenance_number` all fall back to
   `property.phone` when the leasing/maintenance numbers are blank. With no
   main line, there is no destination to forward the call to, so the call is
   not completed and the phone lead is not attributed to the marketing source.

This is why a marketing tracking number is only useful once the property main
line is set.

## Warnings in the app

Nothing here blocks a save — an incomplete property should not prevent
marketing source setup — so the gaps surface as warnings instead:

| Where | Condition | Source |
| --- | --- | --- |
| Marketing Sources list, per source card | `MarketingSource#property_main_line_missing?` (tracking number set, property main line blank) | `app/views/marketing_sources/_marketing_source.html.erb` |
| Marketing Source form, Phone Tracking section | `Property#main_line_missing?` | `app/views/marketing_sources/_form.html.erb` |
| Flash after creating/updating a marketing source | `MarketingSource#property_main_line_missing?` | `MarketingSourcesController#main_line_alert` |
| Property edit form, top-level alert | `Property#main_line_missing?` on a persisted property; escalated when `Property#marketing_tracking_numbers_without_main_line?` | `app/views/properties/_form.html.erb` |
| Property edit form, help text under the Phone field | always shown; flagged when `Property#main_line_missing?` | `app/views/properties/_form_contact.html.erb` |
| Property show page, Phone attribute | `Property#main_line_missing?` | `app/views/properties/_show_property_attributes.html.erb` |

The top-level alert on the property form exists because the Contact
Information fieldset is collapsed by default — help text alone would not be
seen.

## Related

Marketing source names also have to match Yardi Voyager exactly for phone
leads to be attributed there; see [yardi_marketing_source_audit.md](yardi_marketing_source_audit.md).
