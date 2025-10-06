# Lead State System Changes

## Overview
This document describes the changes made to the lead state system to improve clarity for leasing agents.

## Terminology Changes

### States
- **Removed**: `abandoned` state (no longer exists)
- **Renamed**: `disqualified` → `invalidated`

### Events (Actions)
- `claim` → `work`
- `disqualify` → `invalidate`
- `postpone` → `nurture`
- `requalify` → `validate`
- `abandon` → **REMOVED** (use `nurture` instead)
- `revisit` → `reopen`
- `revisit_unit_available` → `reopen_unit_available`

## Philosophy Change
- **Old System**: Leads could be "abandoned" (given up on)
- **New System**: Real leads are never lost - they're nurtured for future opportunities

## Important Behaviors

### Future State & Inactive Properties
When leads are in the `future` state with a `follow_up_at` date:
- The system automatically checks if the property is **active** before reopening
- Leads from **inactive properties will NOT automatically return** to open state
- This is handled in `Lead.process_followups` which checks `lead.property&.active?`

### Migration Handling
When migrating existing `abandoned` leads:
- All leads → moved to `future` state with smart scheduling
- **Smart Scheduling Per Property**:
  - Sorts leads by created_at DESC (newest first)
  - First 50 leads → scheduled 90 days from now
  - Next 50 leads → scheduled 91 days from now
  - Next 50 leads → scheduled 92 days from now
  - Continues until all leads scheduled
- **Benefits**:
  - Prevents flood of leads all returning same day
  - Newer leads return first (more likely to convert)
  - Maximum 50 leads per day per property
  - Inactive property leads will still be blocked by system checks

## State Definitions

### `invalidated`
- Not a real lead (vendor, spam, resident, duplicate)
- Never was a valid prospect

### `future` (nurtured)
- Real lead that's not ready now
- Will be automatically reopened if property is active
- Preserves lead for future opportunities
- **Follow-up Date Range**: 90-275 days (3-9 months)
  - Minimum: 90 days from today
  - Maximum: 275 days from today
  - Quick options: 3, 4, 6, or 9 months
  - Server validates date is within range

## Agent Benefits
1. Clearer distinction between fake leads (invalidated) and real leads (nurtured)
2. No confusion about "disqualified" vs "didn't qualify"
3. Promotes persistent sales culture
4. Inactive property leads won't resurface unexpectedly