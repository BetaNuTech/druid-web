# Common Bluesky Tasks

**Note that all of these instructions may be run in both development and production.**

# Leads

## Re-assigning Leads From Inactive Users

All "in-progress" leads may be reassigned from one user to another, specifying their email addresses. This will also reassign pending tasks for these leads. _Note that disqualified leads and leads that have progressed to resident status will not be modified._

`heroku run "rake leads:reassign[from_user@example.com,to_user@example.com]" --app druid-prod`

## Mass Invalidation

Bluesky does not provide a UI to perform large-scale edits or modification of Leads. These tasks should be performed using the Rails console.

It is highly suggested to trigger a new production database capture and load the production database into development for local testing before performing any mass changes. Document your commands before running them in production.

```
property = Property.active.where(name: "Peyton Stakes").first
time_window = 1.day.ago..
memo = "Mass invalidated because XXX REASON"
leads = Lead.where(property: property, created_at: time_window, state: :open);
puts "#{leads.count} Leads found"
leads.each{|lead| lead.transition_memo = memo; lead.classification = :spam; lead.trigger_event(event_name: 'invalidate')}
```

**Note**: Use `invalidate` for non-real leads (spam, vendors, residents). Use `nurture` for real leads that won't convert now.

## Delete Leads by Phone Number

Safely delete all leads with a specific phone number (useful for cleaning test data). This script handles all associations and checks for foreign key constraints.

```ruby
# Rails console script to delete leads by phone number
# Usage: Paste this into rails console

phone_number = '5551234567'  # Replace with target phone number
leads = Lead.where(phone1: phone_number).or(Lead.where(phone2: phone_number))
puts "Found #{leads.count} leads with phone #{phone_number}"

leads.each do |lead|
  begin
    puts "\nDeleting #{lead.id}: #{lead.name}"

    # Clean up associations
    lead.messages.destroy_all
    lead.duplicate_records.destroy_all
    lead.duplicate_records_by_lead_id.destroy_all
    Note.where(notable: lead).destroy_all
    lead.lead_transitions.destroy_all if lead.respond_to?(:lead_transitions)
    lead.scheduled_actions.destroy_all if lead.respond_to?(:scheduled_actions)
    lead.activities.destroy_all if lead.respond_to?(:activities)

    # Check for Resident reference
    if Resident.where(lead_id: lead.id).exists?
      puts "  Skipped - referenced by Resident"
      next
    end

    # Unlink from raw emails
    CloudmailinRawEmail.where(lead_id: lead.id).update_all(lead_id: nil)

    # Delete the lead
    lead.destroy!
    puts "  ✅ Deleted"
  rescue => e
    puts "  ❌ Error: #{e.message}"
  end
end

remaining = Lead.where(phone1: phone_number).or(Lead.where(phone2: phone_number)).count
puts "\n#{remaining} leads remaining (if any, they're referenced by Residents)"
```

Common test phone numbers to clean up:
- `5551234567` - Common test number
- `5555555555` - Generic test number
- `9999999999` - Another test pattern

**Note**: Leads referenced by Resident records will be skipped to maintain data integrity.

## Standardize Lead Sources

Agents often misspell Lead referral sources when entering manually. You may notice them in the Lead search UI. We have a task which standardizes known variations of Lead referral sources. Update the task at `lib/tasks/leads.rake` as needed to match the names of Marketing Sources.

`heroku run rake leads:referrals:standardize --app druid-prod`

## Reparse Recent "Null" Leads

Marketing sources often change their email formats, and the Lead email parser will fail to parse them. This results in the creation of Leads having "Null" as the first name. After the Lead parser is updated, it may be desired to retry ingestion of these Leads.

The following task will attempt to reparse Leads from the past month.

`heroku run rake leads:incoming:reparse --app druid-prod`

## Analyze Tenacity Scores

Tenacity scores measure how many times agents contact leads before changing their state. The score maxes out at 3 contacts (perfect score of 10). You can analyze tenacity scores for any property using its listing code.

To run a tenacity analysis:

```ruby
# Connect to production console
heroku run rails console --app druid-prod

# Load the analysis script
load 'doc/scripts/tenacity_analysis.rb'

# Run analysis for Vintage Edge (using property code "1002edge")
TenacityAnalysis.new('1002edge').run

# Or use the convenience method
analyze_tenacity('1002edge')

# To analyze more leads per agent (default is 10)
TenacityAnalysis.new('1002edge', lead_limit: 20).run

# Export to CSV format
TenacityAnalysis.new('1002edge').run(format: :csv)
# Or
export_tenacity_csv('1002edge', limit: 20)
```

The analysis shows:
- Individual lead tenacity scores (0-10 scale)
- Contact events for each lead (what type and when)
- Agent summaries (average tenacity, percentage with 3+ contacts)
- Overall property statistics

Note: Only "reportable" leads are included (not disqualified, resident, or exresident states).

## Match CSV Prospects Against Existing Leads

This task compares a CSV file of prospects against existing leads in the database to identify which prospects are already in the system and which are new. It matches by email first, then falls back to name matching with date proximity checking.

### Input CSV Format

Place your CSV file in `tmp/prospects/` directory. The file supports 1-3 rows per prospect:

```
Row 1: Name, Date, Channel, Additional Info
Row 2 (optional): Email or Phone, (empty), Tags, Touchpoint
Row 3 (optional): Phone or Email, (empty), Tags, Touchpoint
```

Supported formats:
- **Name only** (1 row) - for name-based matching
- **Name + Email** (2 rows)
- **Name + Phone** (2 rows)
- **Name + Email + Phone** (3 rows, either order)

Example:
```csv
John Smith,8/12/25,Referral,
johnsmith@email.com,,,
(555) 123-4567,,,
Jane Doe,9/15/25,Organic Search,Web-Desktop
janedoe@email.com,,SEO Touched,Registration
```

Phone numbers are automatically formatted to match the database storage (10-digit strings).

### Running the Task

```bash
# With filename and property code
bundle exec rake 'prospects:match[prospects_1002edge.csv,1002edge]'

# Auto-detect property code from filename
bundle exec rake 'prospects:match[prospects_1002edge.csv]'

# Interactive mode (will prompt for filename)
bundle exec rake 'prospects:match[,1002edge]'

# Production
heroku run "rake 'prospects:match[prospects_1001rawe.csv,1001rawe]'" --app druid-prod
```

### Output Files

The task generates two timestamped CSV files in `tmp/prospects/results/`:

**Matched file** (`[property_code]_matched_[timestamp].csv`):
- Name
- Email
- Phone
- Current State (lead's current status)
- State Changed Date
- Lead ID
- Match Type (email, phone, name, or initial+last)
- Duplicate Count (if multiple matches found)

**Unmatched file** (`[property_code]_unmatched_[timestamp].csv`):
- Name
- Email
- Phone
- Date
- Channel
- Tags/Touches

### Matching Logic

1. **Email Match**: Exact email match at the specified property
2. **Phone Match**: Exact phone match at the specified property (checks both phone1 and phone2 fields)
3. **Full Name Match**: Both first and last name match, with lead created within 30 days of prospect date
4. **Initial+Last Match**: First initial + full last name (e.g., "J Smith" matches "John Smith"), with date proximity
5. **First+Initial Match**: Full first name + last initial (e.g., "John S" matches "John Smith"), with date proximity
6. **Initials Match**: Both first and last initials (e.g., "J S" matches "John Smith"), with date proximity

Phone numbers are normalized before matching (country codes and formatting are removed). All name-based matching requires the lead to be created within 30 days of the prospect date. The task reports statistics showing how many prospects were matched by each method.

## Create Leads from Unmatched Prospects

After running the match task, you can import the unmatched prospects as new leads. This task reads the unmatched CSV file and creates leads in the system.

### Requirements
- CSV must have headers: Name, Email, Phone, Date, Channel, Tags/Touches
- Rows without email OR phone are skipped (must have at least one)
- Leads are created with state: 'open' and priority: 'high'

### Running Locally

```bash
# Dry run mode (preview without creating)
bundle exec rake 'prospects:create_leads[1002edge_unmatched_20251002.csv,1002edge,true]'

# Actually create leads
bundle exec rake 'prospects:create_leads[1002edge_unmatched_20251002.csv,1002edge]'

# File will be found automatically in:
# - tmp/prospects/results/ (where unmatched files are saved)
# - tmp/prospects/
# - current directory
```

### Running on Heroku

Since stdin doesn't pipe through `heroku run`, use one of these methods:

```bash
# Method 1: Upload to S3 or GitHub Gist first
# Upload your CSV to S3 or create a GitHub Gist, then:
heroku run bash --app druid-prod
curl -o /tmp/unmatched.csv "https://your-s3-or-gist-url/file.csv"
bundle exec rake 'prospects:create_leads[/tmp/unmatched.csv,1002edge]'
exit

# Method 2: Inline with heredoc (for smaller files)
heroku run bash --app druid-prod
cat > /tmp/unmatched.csv << 'EOF'
Name,Email,Phone,Date,Channel,Tags/Touches
John Doe,john@example.com,(555) 123-4567,10/1/25,zillow.com,
Jane Smith,jane@example.com,,10/2/25,apartments.com,
EOF
bundle exec rake 'prospects:create_leads[/tmp/unmatched.csv,1002edge]'
exit

# Method 3: Using Rails console (for very small datasets)
heroku run rails console --app druid-prod
# Then paste and run the lead creation code directly
```

### Lead Creation Details

Created leads will have:
- **Source**: "Manual CSV Import" lead source
- **State**: open
- **Priority**: high
- **Referral**: Channel from CSV (e.g., "zillow.com")
- **Notes**: Channel from CSV (date only in notes if unparseable)
- **first_comm**: Set to the date from CSV when the prospect came in

### Safety Features
- Checks for existing leads with same email/phone at the property
- Validates property exists before creating
- Dry run mode for previewing
- Saves results to `tmp/prospects/results/created_leads_[property]_[timestamp].csv`

### Output
The task provides:
- Summary of created/skipped/error counts
- List of skipped duplicates with existing Lead IDs
- CSV file with all created lead IDs for reference

# Users

# Messages

## Retry Delivery

In the event of a service outage, failed delivery of outgoing messages and be retried using a rake task. Specify a time window before the current time in minutes.

`heroku run "rake messages:retry[1440]" --app druid-prod`

# System

## Display System "Notes"

System events are recorded in the `notes` table. You may list recent events using the following rake task.

The rake task options are `[hours,max_displayed]`:

`heroku run "rake notes:report[48,100]" --app druid-prod`

# Deployment Tasks

Any modifications of system data after a deployment are best documented and run in a consistent fashion.

Before deployment:
1. Add code for these tasks as a rake task in `lib/tasks/deployments.rake`
2. Trigger a database capture manually
3. Then run that task in production immediately afterward. `heroku run rake post_deployment:taskname --app druid-prod`
