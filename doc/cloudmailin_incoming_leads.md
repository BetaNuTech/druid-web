# CloudMailin Incoming Leads Documentation

## Overview

CloudMailin is the primary email-to-lead processing system for BlueSky. It receives emails forwarded from property office email addresses and converts them into lead records using either specific parsers or the OpenAI intelligent parser.

## Email Processing Flow

### 1. Email Receipt
- Property office emails are configured to forward all emails to CloudMailin addresses
- CloudMailin receives the email and sends it to the BlueSky API via webhook
- Webhook URL: `/api/v1/leads.json?token=XXX`

### 2. Initial Processing
- API validates the LeadSource token
- Extracts property code from email "to" address (format: `something+PROPERTYCODE@domain.com`)
- Checks content against rejection list

### 3. Asynchronous Processing (with OpenAI enabled)
When `ENABLE_OPENAI_PARSER=true`:
- Email is stored in `CloudmailinRawEmail` table with status `async_processing`
- Returns immediate 200 OK response to CloudMailin
- `ProcessCloudmailinEmailJob` is queued for background processing
- OpenAI analyzes the email and extracts lead information
- Lead is created based on AI analysis

### 4. Synchronous Processing (legacy parsers)
When OpenAI is disabled:
- Specific parsers (Zillow, Apartments.com, etc.) attempt to parse the email
- Lead is created immediately if parsing succeeds
- Falls back to NullParser if no parser matches

## Email Filtering and Rejection

### Content Exception List
Emails are rejected if they contain specific patterns defined in `ContentExceptionList::REJECT`:
- Payment confirmations (e.g., "An application has completed payment")
- Known vendor domains (e.g., "answeradvantage.com", "stealthmonitoring.com")
- Automated system emails

### Company Email Domain Filtering
- Environment variable: `COMPANY_EMAIL_DOMAIN` (default: 'bluecrestresidential.com')
- OpenAI is instructed that emails from this domain are from employees, not leads
- These emails still create lead records but are handled based on OpenAI's analysis:
  - If OpenAI returns `is_lead: false` OR `lead_type` is not 'rental_inquiry':
    - First name: Uses OpenAI's extracted first name, or "Review Required" if none provided
    - Last name: Uses OpenAI's extracted last name, or the humanized lead_type (e.g., "Vendor", "Spam", "Resident")
  - A system note is added with AI classification details for non-rental inquiries

### Property Validation
Emails are rejected if:
- Property doesn't exist for the given property code
- Property is inactive
- Property doesn't have a CloudMailin listing configured
- CloudMailin LeadSource is not found in the system

## Duplicate Detection System

### Overview
The duplicate detection system prevents creating multiple lead records for the same person while allowing legitimate re-inquiries.

### High-Confidence Duplicate Criteria
A lead is considered a high-confidence duplicate if ALL of the following match within 60 days:
- Same first AND last name
- Same email OR phone number
- Same property
- Created within `HIGH_CONFIDENCE_DUPLICATE_MAX_AGE_DAYS` (60 days)

### Auto-Disqualification Rules
Leads are automatically disqualified as duplicates if they match:

1. **Spam Phone Numbers**: Phone matches a lead previously classified as 'spam'
2. **Recent Duplicates**: Same referrer submitted a matching lead recently
3. **Resident Matches**: Contact information matches a current resident
4. **High-Confidence Duplicates**: Meets all criteria above AND:
   - Original lead is classified as 'resident'
   - Same referrer within the duplicate window

### Ignored Values List
The system ignores certain email and phone values when checking for duplicates:
```ruby
# Example ignored emails
'noemail@gmail.com'
'none@none.com'
'noemail@bluestone-prop.com'
'noemail@bluecrestresidential.com'
'abc123@gmail.com'

# Example ignored phones
'1111111111'
'0000000000'
'9999999999'
```

### Duplicate Detection Process
1. After lead creation, `mark_duplicates` runs asynchronously
2. Searches for possible duplicates based on:
   - Phone numbers (phone1, phone2)
   - Email address
   - Name combination (first + last)
   - Remote ID
3. Creates `DuplicateLead` records linking potential duplicates
4. Runs `auto_disqualify` checks
5. If not auto-disqualified, lead remains active but linked to duplicates

## Lead Classification

### Classification Types
- **lead**: Legitimate rental inquiry
- **vendor**: Business/service provider contact
- **resident**: Current resident communication
- **spam**: Spam or irrelevant contact
- **duplicate**: Duplicate of an existing lead
- **lost**: Lead that was lost/not converted
- **parse_failure**: Email couldn't be parsed properly

### OpenAI Classification
When OpenAI parser is enabled, it classifies emails as:
- `rental_inquiry`: Legitimate rental leads
- `resident`: Current resident communications
- `vendor`: Vendor/service provider emails
- `spam`: Spam or irrelevant emails
- `unknown`: Cannot determine type

### Classification Notes
For non-rental inquiries, the system adds a note with:
- AI Classification type
- Reason for classification
- Confidence score (0-100%)

## Lead States and Disqualification

### Disqualified State
When a lead is disqualified:
- State changes to 'disqualified'
- Priority is set to 0
- All scheduled tasks are cleared
- All messages are marked as read
- Cannot be reopened without manual intervention

### Common Disqualification Reasons
1. Resident match
2. High-confidence duplicate
3. Spam phone number
4. Manual disqualification by agent
5. Parse failure (for junk leads)

## Operations and Troubleshooting

### Monitoring Commands

#### Rake Tasks
```bash
# View statistics
rake cloudmailin:stats

# Retry failed emails
rake cloudmailin:retry_failed

# Process pending emails
rake cloudmailin:process_pending

# Clean up old emails (30+ days)
rake cloudmailin:cleanup
```

#### Console Commands
```ruby
# Check all failed emails
CloudmailinRawEmail.failed.order(created_at: :desc).each do |e|
  puts "ID: #{e.id}"
  puts "Created: #{e.created_at}"
  puts "Error: #{e.error_message}"
  puts "From: #{e.raw_data.dig('headers', 'From')}"
  puts "---"
end; nil

# Check emails from company domain
CloudmailinRawEmail.where("raw_data::text ILIKE '%bluecrestresidential.com%'").each do |e|
  puts "#{e.created_at} | Status: #{e.status} | Lead: #{e.lead_id || 'None'}"
end; nil

# Check processing status
CloudmailinRawEmail.group(:status).count

# Find specific email by sender
CloudmailinRawEmail.where("raw_data::text ILIKE '%sender@example.com%'").last
```

### Common Failure Scenarios

#### 1. "Property does not have Cloudmailin listing configured"
- **Cause**: Property exists but no CloudMailin listing
- **Fix**: Add CloudMailin listing to property or ensure property code is correct

#### 2. "Email received for inactive property"
- **Cause**: Property is marked as inactive
- **Fix**: Activate property or update forwarding rules

#### 3. "Cloudmailin lead source not found in system"
- **Cause**: CloudMailin LeadSource missing from database
- **Fix**: Run `rake db:seed:lead_sources` to ensure LeadSource exists

#### 4. OpenAI Processing Failures
- **Cause**: Rate limits, service outages, or API errors
- **Fix**: Emails automatically retry; check `rake cloudmailin:retry_failed`

### Investigating Missing Leads

1. **Check CloudmailinRawEmail table**:
   ```ruby
   # Find by email address
   CloudmailinRawEmail.where("raw_data::text ILIKE '%email@example.com%'").last
   ```

2. **Check if lead was created but disqualified**:
   ```ruby
   Lead.where(email: 'email@example.com').last
   ```

3. **Check duplicate detection**:
   ```ruby
   # Find all leads with matching email
   Lead.where(email: 'email@example.com').order(created_at: :desc)
   
   # Check if marked as duplicate
   Lead.where(email: 'email@example.com', classification: 'duplicate')
   ```

4. **Check resident matching**:
   ```ruby
   # This would require checking if email belongs to a resident
   property = Property.find(property_id)
   Lead.open_possible_residents(property)
   ```

## Configuration

### Environment Variables
```bash
# Enable OpenAI parser (recommended)
ENABLE_OPENAI_PARSER=true

# OpenAI configuration
OPENAI_API_TOKEN=your-api-key
OPENAI_ORG=your-org-id  # Optional
OPENAI_MODEL=gpt-4o-mini  # Default

# Company email domain
COMPANY_EMAIL_DOMAIN=bluecrestresidential.com

# CloudMailin debugging
DEBUG_MESSAGE_API=true
```

### Feature Flags
- `lead_automatic_dedupe`: Enable automatic duplicate detection and disqualification

## Best Practices

1. **Property Email Forwarding**
   - Forward ALL property emails to CloudMailin
   - Use plus addressing for property codes: `address+PROPERTYCODE@cloudmailin.net`

2. **Monitoring**
   - Run `cloudmailin:stats` daily to check for failures
   - Monitor for patterns in failed emails
   - Review "Review Required" leads regularly

3. **Duplicate Management**
   - Let the system handle automatic duplicates
   - Manually review borderline cases
   - Use 60-day window for high-confidence matching

4. **Testing**
   - Always test with property's actual CloudMailin address
   - Verify property code extraction
   - Check that property has active CloudMailin listing