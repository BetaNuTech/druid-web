# Lead Speed: Business Hours Calculation

## Overview

Lead Speed measures the time from when a lead is created until the first contact is made by an agent. As of the business hours implementation, Lead Speed now only counts time that elapses during each property's configured office hours.

This ensures agents are not penalized for leads that come in outside of business hours (evenings, weekends, or when the office is closed).

## How It Works

### Timer Behavior

1. **Lead created during business hours**: Timer starts immediately at lead creation time
2. **Lead created outside business hours**: Timer starts when the office next opens
3. **Timer crosses non-business hours**: Timer automatically pauses during closed hours and resumes when office reopens

### Property-Specific Configuration

Each property has its own office hours configuration with:
- Morning hours (e.g., 6:00 AM - 12:00 PM)
- Afternoon hours (e.g., 1:00 PM - 5:00 PM)
- Lunch breaks (gap between morning and afternoon)
- Days of the week the office is open/closed
- Holidays observed
- Timezone

The Lead Speed calculation uses the **property's actual configured office hours**, not a generic "business hours" definition.

### 48-Hour Cap

For leads where the total elapsed time exceeds 48 hours (2880 minutes):
- The system falls back to simple time calculation (total elapsed time)
- Business hours logic is NOT applied
- Rationale: These leads are already graded as 'C' (poor response time), so the additional complexity of business hours calculation provides no value

### Grading Scale

The grading scale remains unchanged:
- **Grade A**: 0-29 minutes (business hours only)
- **Grade B**: 30-120 minutes (business hours only)
- **Grade C**: 120+ minutes (business hours only)
- **Grade N/A**: No contact made or not reportable

## Examples

### Example 1: Lead Created Outside Office Hours

**Scenario:**
- Property office hours: 6:00 AM - 5:00 PM, Monday-Friday
- Lead created: Friday 8:00 PM
- Contact made: Monday 7:00 AM

**Calculation:**
- Timer starts: Monday 6:00 AM (when office opens)
- Timer stops: Monday 7:00 AM (when contact made)
- **Lead Time: 60 minutes**
- **Grade: B**

### Example 2: Lead Spanning Lunch Break

**Scenario:**
- Property office hours: 6:00 AM - 12:00 PM, 1:00 PM - 5:00 PM (1-hour lunch)
- Lead created: Monday 11:00 AM
- Contact made: Monday 2:00 PM (3 hours later)

**Calculation:**
- Business hours counted:
  - 11:00 AM - 12:00 PM = 60 minutes (morning)
  - 12:00 PM - 1:00 PM = 0 minutes (lunch, not counted)
  - 1:00 PM - 2:00 PM = 60 minutes (afternoon)
- **Lead Time: 120 minutes**
- **Grade: B**

### Example 3: Lead Spanning Multiple Days

**Scenario:**
- Property office hours: 6:00 AM - 12:00 PM, 1:00 PM - 5:00 PM, Monday-Friday (closed weekends)
- Lead created: Friday 9:00 AM
- Contact made: Monday 10:00 AM

**Calculation:**
- Business hours counted:
  - Friday: 9:00 AM - 12:00 PM (3 hrs) + 1:00 PM - 5:00 PM (4 hrs) = 420 minutes
  - Saturday: 0 minutes (closed)
  - Sunday: 0 minutes (closed)
  - Monday: 6:00 AM - 10:00 AM = 240 minutes
- **Lead Time: 660 minutes (11 hours)**
- **Grade: C**

### Example 4: Lead Exceeding 48 Hours

**Scenario:**
- Lead created: Monday 9:00 AM
- Contact made: Friday 9:00 AM (4 days later)

**Calculation:**
- Total elapsed time: 96 hours = 5,760 minutes
- Since > 2,880 minutes (48 hours), use simple calculation
- **Lead Time: 5,760 minutes**
- **Grade: C**

## Special Cases

### Phone-Sourced Leads

Leads that come from phone sources (Twilio) continue to receive automatic 0-minute lead time:
- These leads represent incoming calls where the lead is already in contact
- Business hours logic does NOT apply
- **Lead Time: 0 minutes**
- **Grade: A**

### Leads Without Properties

If a lead has no associated property:
- Falls back to simple time calculation (total elapsed time)
- No business hours adjustment applied
- This is a failsafe to ensure lead time is always calculated

### Calculation Errors

If the business hours calculation fails for any reason:
- System automatically falls back to simple time calculation
- A warning is logged to Rails logger
- Lead time is still calculated and recorded

## Technical Implementation

### File Locations

- **Lead time calculation**: `/app/models/concerns/leads/contact_events.rb:122-153`
- **Business hours methods**: `/app/models/concerns/properties/working_hours.rb`
- **Tests**: `/spec/models/concerns/leads/contact_events_business_hours_spec.rb`

### Key Methods

- `contact_lead_time(first_contact, timestamp)` - Calculates lead time using business hours
- `property.working_hours_difference_in_time(from, to)` - Returns working minutes between two times
- `property.office_open?(datetime)` - Checks if given time is during office hours

### Algorithm

```ruby
def contact_lead_time(first_contact, timestamp)
  compare_timestamp = (first_contact ? created_at : last_comm).to_time
  simple_elapsed_minutes = ((timestamp.to_time - compare_timestamp).to_i / 60).to_i

  # Apply 48-hour cap
  if simple_elapsed_minutes > 2880
    return simple_elapsed_minutes
  end

  # Use property's business hours if available
  if property.present?
    business_hours_minutes = property.working_hours_difference_in_time(
      compare_timestamp,
      timestamp.to_time
    )
    return [business_hours_minutes, 1].max
  end

  # Fallback
  simple_elapsed_minutes
end
```

## Impact on Statistics

### Going Forward

All new contact events created after this implementation will use business hours calculation for lead time.

### Historical Data

Historical contact events are **not recalculated**. This means:
- Past lead speed statistics remain unchanged
- Only new leads (created after deployment) use business hours logic
- This prevents data inconsistency and maintains historical accuracy

### Statistics Generation

The hourly statistics rake tasks continue to work unchanged:
- `rake statistics:leadspeed:generate` - Generates hourly stats
- `rake statistics:leadspeed:backfill_daily` - Backfills daily stats
- `rake statistics:rollup` - Rolls up to daily, weekly, monthly

The statistics use the `lead_time` value stored in the `contact_events` table, which now reflects business hours for new leads.

## Monitoring & Validation

### After Deployment

1. Monitor new lead time calculations on staging
2. Compare a sample of business hours calculations to expected values
3. Verify statistics generation continues to work correctly
4. Check for any errors in Rails logs related to business hours calculation

### Testing Strategy

Comprehensive test coverage includes:
- Leads created during vs. outside business hours
- Leads spanning lunch breaks
- Leads spanning multiple days and weekends
- 48-hour cap behavior
- Phone lead exemption
- Leads without properties
- Calculation error handling
- Integration with contact event creation

## Benefits

1. **Fair Metrics**: Agents are not penalized for leads arriving outside working hours
2. **Property-Specific**: Uses each property's actual office hour configuration
3. **Accurate Grading**: Lead Speed grades reflect actual working time to respond
4. **Transparent**: Clear rules and fallbacks for edge cases
5. **Performant**: 48-hour cap prevents expensive calculations for old leads

## Maintenance

### Updating Property Office Hours

When a property's office hours change:
- New leads will immediately use the updated hours
- Historical lead times are not recalculated
- No special migration or data update needed

### Troubleshooting

If lead times seem incorrect:
1. Verify property office hours configuration in admin panel
2. Check property timezone setting
3. Look for warnings in Rails logs about failed calculations
4. Verify the lead has an associated property
5. Check if lead is from a phone source (automatic 0 minutes)

## Future Enhancements

Potential future improvements:
- Admin report showing average business hours response time by property
- Dashboard widget comparing business hours vs. total elapsed time
- Historical data recalculation option (one-time migration)
- Agent notifications for leads nearing Grade B/C thresholds during business hours
