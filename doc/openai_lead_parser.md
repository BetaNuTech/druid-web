# OpenAI Lead Parser Documentation

## Overview

The OpenAI Lead Parser is an intelligent email parsing system that replaces specific lead source parsers (Zillow, Apartments.com, etc.) with a single AI-powered parser that can understand any email format, including forwarded emails.

## Architecture

### Components

1. **OpenaiClient** (`app/services/openai_client.rb`)
   - Handles communication with OpenAI API
   - Implements retry logic with exponential backoff
   - Circuit breaker pattern for API outages
   - Structured JSON responses for consistent parsing

2. **CloudmailinRawEmail** (`app/models/cloudmailin_raw_email.rb`)
   - Stores raw email data for async processing
   - Tracks processing status and retry attempts
   - Links to created leads

3. **ProcessCloudmailinEmailJob** (`app/jobs/process_cloudmailin_email_job.rb`)
   - Async job for processing emails with OpenAI
   - Handles retries for rate limits and service errors
   - Creates leads or fallback records

4. **OpenaiParser** (`app/lib/leads/adapters/cloud_mailin/openai_parser.rb`)
   - Integrates with existing CloudMailin parser infrastructure
   - Returns placeholder data for immediate response

## Configuration

### Environment Variables

```bash
# Enable OpenAI parser (default: false)
ENABLE_OPENAI_PARSER=true

# OpenAI API credentials
OPENAI_API_TOKEN=your-api-key
OPENAI_ORG=your-organization-id # Optional
OPENAI_MODEL=gpt-4o-mini # Default: gpt-4o-mini
```

## How It Works

1. **Email Receipt**: CloudMailin webhook receives email
2. **Storage**: Raw email stored in `cloudmailin_raw_emails` table
3. **Immediate Response**: Returns 200 OK with placeholder lead data
4. **Async Processing**: Background job analyzes email with OpenAI
5. **Lead Creation**: Creates/updates lead based on AI analysis
6. **Error Handling**: Retries on failures, creates fallback leads if needed

## Features

### Intelligent Classification

The AI classifies emails as:
- `rental_inquiry`: Legitimate rental leads
- `resident`: Current resident communications
- `vendor`: Vendor/service provider emails
- `spam`: Spam or irrelevant emails
- `unknown`: Cannot determine type

### Lead Source Matching

The AI attempts to match emails to active lead sources by analyzing:
- Email subject patterns
- Sender domains
- Email content mentions

### Data Extraction

Extracts all standard lead fields:
- First/Last name
- Email address
- Phone numbers
- Message content
- Preferred move-in date
- Unit type preferences
- Company information

### Handling Special Cases

#### Uncertain/Spam Emails
- Creates lead with descriptive names (e.g., "Review Required - Vendor Email")
- Adds classification note for agent review
- Preserves all available contact information

#### Forwarded Emails
- Handles any email format, including forwards
- Extracts information from forwarded content
- No longer fails due to HTML structure changes

#### Inactive Properties
- Logs warning for emails to inactive properties
- Does not create leads
- Tracks in error notes

## Operations

### Monitoring

```bash
# View CloudMailin email statistics
bundle exec rake cloudmailin:stats

# Retry failed emails
bundle exec rake cloudmailin:retry_failed

# Process pending emails
bundle exec rake cloudmailin:process_pending

# Clean up old processed emails (30+ days)
bundle exec rake cloudmailin:cleanup
```

### Database Queries

```ruby
# View recent failures
CloudmailinRawEmail.failed.order(created_at: :desc).limit(10)

# Check processing status
CloudmailinRawEmail.group(:status).count

# Find emails for a property
CloudmailinRawEmail.where(property_code: 'ABC123')
```

## Error Handling

### Retry Strategy

1. **Rate Limits**: Wait 1 minute, retry up to 3 times
2. **Service Errors**: Wait 5 minutes, retry up to 2 times
3. **Circuit Breaker**: Opens after service errors, 5-minute cooldown

### Fallback Behavior

When OpenAI is unavailable after retries:
1. Creates lead with "OpenAI Processing Failed" name
2. Includes raw email data in lead notes
3. Marks for manual review

## Migration Path

### Enabling OpenAI Parser

1. Run database migration:
   ```bash
   bundle exec rails db:migrate
   ```

2. Set environment variables:
   ```bash
   ENABLE_OPENAI_PARSER=true
   OPENAI_API_TOKEN=your-key
   ```

3. Deploy and monitor

### Rollback

To disable and revert to specific parsers:
```bash
ENABLE_OPENAI_PARSER=false
```

## Cost Considerations

- Each email analysis costs approximately $0.001-0.003 (depending on email size)
- Monitor usage via OpenAI dashboard
- Consider caching common patterns to reduce API calls

## Future Enhancements

1. **Pattern Learning**: Cache successful parsing patterns
2. **Batch Processing**: Process multiple emails in one API call
3. **Custom Training**: Fine-tune model on historical lead data
4. **Analytics**: Track parser accuracy and lead quality metrics