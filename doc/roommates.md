# Roommate Management in BlueSky

## Overview

The BlueSky application includes comprehensive roommate management functionality that allows tracking and communication with all parties involved in a rental application, not just the primary applicant. This feature is essential for managing guarantors, co-applicants, spouses, and other occupants associated with a lead.

## Database Structure

Roommates are stored in a dedicated `roommates` table with the following key fields:

- **Personal Information**: `first_name`, `last_name`
- **Contact Information**: `phone`, `email`
- **Relationship Data**: 
  - `relationship` (enum: other, spouse, dependent)
  - `occupancy` (enum: resident, guarantor, child)
- **Communication Preferences**: 
  - `sms_allowed` (default: false)
  - `email_allowed` (default: true)
- **Additional**: `notes`, `remoteid` (for external system references)

## Core Features

### 1. Multi-Party Communication

Roommates are fully integrated into the messaging system:

- **Individual Message Threads**: Each roommate can have their own conversation thread separate from the lead
- **Communication Preferences**: Individual opt-in/opt-out settings for SMS and email
- **Message Tracking**: System automatically logs when messages are sent to/from roommates
- **Template Support**: Roommates have access to the same message template data as leads

### 2. Relationship Types

The system categorizes roommates by:

- **Occupancy Type**:
  - `resident`: Will live in the unit
  - `guarantor`: Financial backer (parent, sponsor, etc.)
  - `child`: Minor dependent

- **Relationship**:
  - `spouse`: Married partner
  - `dependent`: Financial dependent
  - `other`: Any other relationship

### 3. Business Logic

- **Responsible for Lease**: The system automatically marks guarantors and residents as "responsible for lease"
- **Role Detection**: Helper methods like `guarantor?`, `spouse?`, `minor?`, and `responsible?` facilitate business logic
- **Audit Trail**: All changes to roommate records are tracked via the `audited` gem

## User Interface

### Accessing Roommates

- Roommates are accessed via nested routes under leads: `/leads/:lead_id/roommates`
- Full CRUD operations are available through the `RoommatesController`
- Authorization is controlled via `RoommatePolicy` using Pundit

### Display Information

On the lead detail page, roommates are shown with:
- Name and relationship type
- Occupancy classification
- Contact information with visual indicators for communication preferences
- Notes field for additional context

## Integration Points

### 1. Messaging System

When sending messages to roommates:
- Messages use the polymorphic `messageable` association
- Thread IDs are maintained for conversation continuity
- Email replies are routed back to the correct roommate thread

### 2. Yardi Voyager Export

The system can export roommate data to Yardi with appropriate mappings:
- Guarantors → 'guarantor' record type
- Spouses → 'spouse' record type
- Children → 'other' record type
- Others → 'roommate' record type

## Use Cases

### Common Scenarios

1. **Guarantor Management**
   - Track parent or sponsor information for students or first-time renters
   - Maintain separate communication channels with financial backers
   - Document guarantor agreements and requirements

2. **Co-Applicant Tracking**
   - Multiple unrelated adults sharing a unit
   - Each person's contact preferences and information
   - Individual messaging threads for coordination

3. **Family Applications**
   - Spouse information with appropriate relationship marking
   - Dependent children documentation
   - Emergency contact information

### What Roommates Are NOT Used For

- **Lead Duplicate Detection**: Only the primary lead is checked for duplicates
- **Marketing Analytics**: Roommate data is not included in marketing reports
- **Automated Policies**: Engagement policies only apply to leads, not roommates
- **CSV Exports**: Standard lead exports do not include roommate information

## Technical Implementation

### Models and Concerns

- **Model**: `app/models/roommate.rb`
- **Messaging Concern**: `app/models/concerns/roommates/messaging.rb`
- **Lead Association**: Through `app/models/concerns/leads/roommates.rb`

### Key Validations

- Requires first and last name
- Must have either phone or email
- Phone numbers are automatically formatted

### Security

- Access controlled through property-based authorization
- Users can only view/edit roommates for leads in their assigned properties
- All actions are audited for compliance

## Best Practices

1. **Always Collect Guarantor Information**: For applications requiring guarantors, ensure their information is captured as a roommate with `occupancy: 'guarantor'`

2. **Respect Communication Preferences**: Always check `sms_allowed` and `email_allowed` before sending messages

3. **Use Appropriate Relationships**: Properly categorize roommates to ensure correct handling in Yardi exports and business logic

4. **Document Special Cases**: Use the notes field to capture any special circumstances or requirements

## Future Considerations

While the roommate infrastructure is robust, some areas could be enhanced:

- Include roommates in duplicate detection logic
- Add roommate data to lead exports when needed
- Consider roommates in automated engagement policies
- Enhance reporting to include roommate analytics

The roommate feature provides essential functionality for managing the complex relationships involved in modern rental applications, ensuring all parties can be properly tracked and communicated with throughout the leasing process.