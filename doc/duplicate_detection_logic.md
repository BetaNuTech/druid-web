# BlueSky Duplicate Lead Detection Logic

## Overview

BlueSky has sophisticated duplicate detection that runs automatically when leads are created or updated. This system helps identify and auto-invalidate duplicate leads to prevent agents from working the same prospect multiple times.

## Duplicate Detection Criteria

### Primary Matching Fields (Line 100-133 in `app/models/concerns/leads/duplicates.rb`)

The `possible_duplicates` method identifies duplicates based on **ANY** of the following matches:

1. **Phone1 Match**: `phone1 = :phone1`
2. **Phone2 Match**: `phone2 = :phone2`
3. **Email Match**: `email = :email`
4. **Remote ID Match**: `remoteid = :remoteid` (Yardi ProspectID)
5. **Name Match**: `first_name = :first_name AND last_name = :last_name`

**IMPORTANT**: These are **OR conditions**, meaning a lead is considered a possible duplicate if it matches on **ANY** of these fields, not all of them.

### High Confidence Duplicates (Line 335-369)

The `high_confidence_duplicates` method is more restrictive and requires:

- **Created within last 60 days** (`HIGH_CONFIDENCE_DUPLICATE_MAX_AGE_DAYS = 60`)
- **Same property**
- **Same first AND last name** (both must match)
- **Same email OR same phone1** (at least one must match)

This is used for auto-invalidation logic.

## Impact on Yardi Sync

### Does Duplicate Detection Prevent Yardi Sync?

**No, duplicate detection does NOT prevent sync to Yardi.** However, it may trigger **auto-invalidation** which then prevents sync.

### Auto-Invalidation Logic (Line 244-326)

Leads are automatically invalidated (and thus won't sync) if:

1. **Spam Match**: Phone number matches a lead classified as spam (Line 266)

2. **Feature Flag Disabled**: `Flipflop.enabled?(:lead_automatic_dedupe)` is off (Line 269)

3. **Lea AI Leads**: Lead is assigned to system user or has `lea_conversation_url` (Line 258-263)

4. **Matching Lead Already Being Worked**: A duplicate exists in 'prospect', 'showing', 'application', or 'approved' state (Line 285-297)
   - If current lead is 'open' → auto-invalidate
   - If duplicate was created first → auto-invalidate

5. **Same ILS, Recent, Open**: Duplicate from same referrer submitted within 48 hours and still open (Line 303-312)

6. **Matching Resident**: Duplicate exists and is a current resident (Line 314-321)

### Why Leads with remoteid Might Not Be in Yardi CSV

If a lead has a `remoteid` but doesn't appear in your Yardi CSV export, possible reasons:

1. **Guest Card is Canceled**: The guest card exists in Yardi but has `Type="canceled"` and was excluded from your CSV export
2. **Guest Card was Deleted**: Someone manually deleted the guest card in Yardi (rare)
3. **Duplicate Guest Card**: Yardi created a duplicate with a different ProspectID
4. **Export Filter Mismatch**: Your CSV export filters excluded this guest card (by date, status, etc.)
5. **Property Mismatch**: The guest card exists but under a different property code

## Duplicate Detection Does NOT Use Name Alone

**CRITICAL FINDING**: The duplicate detection system **DOES use name matching**, but **ONLY in combination with phone/email/remoteid**.

From line 122-127:
```ruby
OR ( first_name IS NOT NULL
     AND first_name != ''
     AND first_name = :first_name
     AND last_name = :last_name
     AND first_name NOT IN (#{invalid_values_sql})
   )
```

This means:
- Two leads with the **same name but different phone/email** will be flagged as duplicates
- Two leads with **different names but same phone** will be flagged as duplicates

**If you only want phone/email matching (NOT name)**, you would need to modify the `possible_duplicates` SQL query to remove the name matching condition.

## When Duplicates Are Checked

1. **After Create**: `after_create :mark_duplicates` (Line 13)
2. **After Save**: `after_save :duplicate_check_on_update` (Line 14)
3. **Only if attributes changed**: Phone1, Phone2, Email, First Name, Last Name, or remoteid (Line 17)

## Skip Duplicate Detection

You can bypass duplicate detection by setting `lead.skip_dedupe = true` before saving.

This is used during Yardi imports to prevent avalanche of dedupe jobs:
```ruby
lead.skip_dedupe = true
lead.save
```

## Ignored Values

The system ignores common placeholder values like:
- Phone: '5555555555', '0000000000', '1234567890', etc.
- Email: 'noemail@gmail.com', 'none@none.com', 'unknown@noemail.com', etc.
- Name: 'Unknown', 'None', 'Unavailable', etc.

See full list at lines 18-89.

## Recommendations

### To Prevent Name-Based Duplicate Detection

If you want to **remove name-based duplicate matching** (so two people with the same name but different contact info aren't flagged):

Modify `app/models/concerns/leads/duplicates.rb` line 122-127 and remove the name matching OR condition.

### To Debug Sync Issues

1. Check if lead was auto-invalidated due to duplicate detection
2. Check if the duplicate has a remoteid that conflicts
3. Use the `verify_yardi_remoteids.rb` script to query Yardi API directly
4. Review lead's `classification` and `transition_memo` fields for auto-invalidation reasons

### Current Behavior Summary

- **Duplicate Detection**: Matches on phone, email, remoteid, OR name (any one triggers)
- **Auto-Invalidation**: Only happens if high-confidence duplicate meets specific criteria
- **Yardi Sync**: Not prevented by duplicate detection alone, only by auto-invalidation
- **remoteid Matching**: If two leads have the same remoteid, they are duplicates (this could cause sync issues)
