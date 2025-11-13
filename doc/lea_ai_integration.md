# Lea AI Integration

## Overview

BlueSky integrates with Lea AI, an AI-powered leasing assistant that handles initial prospect inquiries via Yardi Voyager. This integration allows properties to automate initial lead engagement while maintaining seamless handoff to human agents when appropriate.

## How It Works

### For Properties WITHOUT Lea AI Enabled

When `lea_ai_handling` is disabled (default):
- Incoming leads are processed normally
- No special system user assignment
- Standard lead workflow applies

### For Properties WITH Lea AI Enabled

When `lea_ai_handling` is enabled for a property:

1. **Regular Lead Arrives via CloudMailin**
   - OpenAI analyzes the email
   - If it's a rental inquiry (not a Lea handoff):
     - Lead is assigned to **system user** (Bluesky)
     - Lead state changes to **prospect**
     - Guest card created in Yardi with **"Admin"** agent
     - Lea AI picks up the lead in Yardi (looks for Admin-assigned leads)
     - Lea begins AI conversation with the prospect

2. **Lea Handoff Email Arrives**
   - OpenAI detects handoff email (contains "Guest Card Details:", "handoff", signature from "Lea")
   - Lead is created in **open state, unassigned**
   - Conversation URL is extracted and stored
   - System note added with handoff reason and conversation link
   - Leasing agent can claim the lead and continue the conversation

## Configuration

### Enable Lea AI for a Property

1. Navigate to Property Settings → Preferences
2. Check "Lea AI Handling" checkbox
3. Save

The setting is stored in the property's `appsettings` JSONB column as `lea_ai_handling`.

### Access via Code

```ruby
property.lea_ai_handling?  # Returns true/false
```

## Monitoring Lea AI Pipeline

### Find Leads Awaiting Handoff

Use the lead search page:
1. Filter by Agent: Select "Bluesky" (system user)
2. These are leads currently being handled by Lea AI
3. Waiting for Lea to send handoff email

### Identify Handoff Leads

Leads with a Lea conversation URL:
```ruby
Lead.where.not(lea_conversation_url: nil)
```

On the lead show page, if `lea_conversation_url` is present, a button appears to view the Lea AI conversation.

## Duplicate Handling

### Automatic Behavior

The system prevents auto-invalidation in two scenarios:

1. **Leads assigned to system user** are **not** auto-invalidated as duplicates
   - This prevents the original CloudMailin lead from being invalidated while Lea works it

2. **Lea handoff leads** (with conversation URL) are **not** auto-invalidated as duplicates
   - Handoff leads will naturally match the system user's lead (same contact info)
   - Both leads are preserved for manual review
   - Leasing agents can manually invalidate the original after claiming the handoff lead

### Manual Invalidation

Users can invalidate leads assigned to the system user (even though normally they can't invalidate other agents' leads). This allows cleanup of the original lead when the handoff lead is the one to work.

### Typical Flow

1. Regular lead arrives → assigned to system user (not auto-invalidated)
2. Lea AI works the lead
3. Lea sends handoff → creates new lead (not auto-invalidated, despite being duplicate)
4. Both leads marked as duplicates but neither auto-invalidated
5. Agent claims handoff lead, manually invalidates the system user's lead

## Guest Card Behavior

### Admin Agent Assignment

When a lead assigned to the system user is synced to Yardi:
- Agent is set to **"Admin"** instead of system user name
- This signals to Lea AI that the lead is available for AI handling
- Lea's system filters for guest cards with "Admin" agent

### After Handoff

When the handoff lead is created:
- It's in open state, unassigned
- When an agent claims it, the agent's name will be used in Yardi
- Guest card updates with the real agent's name

## Technical Details

### Database Schema

**New fields:**
- `leads.lea_conversation_url` (string) - URL to Lea AI conversation

**Existing fields:**
- `properties.appsettings` (jsonb) - Contains `lea_ai_handling` flag

### OpenAI Prompt Updates

The OpenAI system prompt now includes:
- New lead_type: `"lea_handoff"`
- Detection criteria for Lea handoff emails
- Extraction of conversation URL and handoff reason

### Detection Criteria

A Lea handoff email is identified when ALL of these are present:
1. Email body contains "Guest Card Details:" (case-insensitive)
2. Email body contains "handoff" (case-insensitive)
3. Email signature contains "Lea" or from address contains "lea@"
4. Email contains a "View conversation" link

### Key Files Modified

**Models:**
- `app/models/concerns/properties/appsettings.rb` - Added lea_ai_handling setting
- `app/models/lead.rb` - Added lea_conversation_url validation
- `app/models/concerns/leads/duplicates.rb` - Skip auto-invalidation for system user leads AND Lea handoff leads

**Services:**
- `app/services/openai_client.rb` - Updated system prompt for Lea detection
- `app/jobs/process_cloudmailin_email_job.rb` - Lea handoff and system user assignment logic

**Yardi Integration:**
- `app/lib/yardi/voyager/data/guest_card.rb` - Admin agent for system user leads

**Search:**
- `app/models/lead_search.rb` - Include system user in agent filter

**Views:**
- `app/views/leads/show.html.erb` - Lea conversation link display
- `app/views/leads/_comment_card.html.erb` - Linkify URLs in notes

**Helpers:**
- `app/helpers/leads_helper.rb` - linkify_note_content helper

**Policies:**
- `app/policies/lead_policy.rb` - Allow invalidation of system user leads

## Best Practices

### 1. Testing Before Rollout

- Enable on ONE test property first
- Send test leads and verify system user assignment
- Confirm Yardi guest cards show "Admin" agent
- Test Lea handoff email detection
- Verify conversation links work

### 2. Agent Training

Train leasing agents on:
- How to find leads in the Lea AI pipeline (filter by system user)
- What a Lea handoff email means
- How to access the conversation history
- When to invalidate duplicate leads

### 3. Monitoring

Regularly check:
- Leads assigned to system user (shouldn't stay there indefinitely)
- Lea handoff emails being detected correctly
- Duplicate lead situations resolved appropriately

### 4. Troubleshooting

**Lead not assigned to system user:**
- Check if property has `lea_ai_handling` enabled
- Verify lead came via CloudMailin
- Check OpenAI classified it as "rental_inquiry" (not spam/vendor)

**Handoff not detected:**
- Verify email contains all required markers
- Check OpenAI response in CloudmailinRawEmail record
- Review system notes on the lead for error messages

**Guest card not showing Admin:**
- Confirm property has `lea_ai_handling` enabled
- Verify lead.user is the system user
- Check Yardi sync logs

## Migration Path

### Enabling Lea AI for Existing Properties

1. Coordinate with property manager
2. Enable setting in staging first
3. Test with real Lea handoff emails
4. Monitor for 1 week
5. Enable in production when confident
6. Provide agent training before go-live

### Disabling Lea AI

If Lea AI is no longer needed:
1. Disable `lea_ai_handling` setting
2. Manually reassign any leads still with system user
3. Existing conversation URLs will remain accessible
4. Future leads will process normally

## Support

For issues or questions:
- Check CloudmailinRawEmail records for parsing errors
- Review lead system notes for error messages
- Check Papertrail logs for "Lea" or "system user"
- Contact development team with lead ID and property name
