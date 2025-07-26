# Implementation Plan: System User for Automated Messages

## Overview
This plan outlines the implementation of a dedicated system user named "Bluesky" to handle all automated messages in the BlueSky application. This will provide better visibility and tracking of system-generated communications.

## Goals
- Create a special "Bluesky" user for all automated messages
- Ensure all automated SMS and email messages show "Bluesky" as the sender
- Maintain audit trail and message integrity
- Prevent accidental modification or deletion of the system user

## Implementation Steps

### Step 1: Add System User Flag to Users Table
Create migration to add a boolean flag identifying system users.

**File**: `db/migrate/[timestamp]_add_system_user_flag_to_users.rb`

```ruby
class AddSystemUserFlagToUsers < ActiveRecord::Migration[6.1]
  def change
    add_column :users, :system_user, :boolean, default: false, null: false
    add_index :users, :system_user, where: "system_user = true", unique: true
  end
end
```

### Step 2: Create System User Migration
Create migration to add the "Bluesky" system user.

**File**: `db/migrate/[timestamp]_create_bluesky_system_user.rb`

```ruby
class CreateBlueskySystemUser < ActiveRecord::Migration[6.1]
  def up
    # Find or create administrator role
    admin_role = Role.find_by(name: 'Administrator')
    
    # Create system user
    system_user = User.create!(
      email: 'system@bluesky.internal',
      password: SecureRandom.hex(32),
      role: admin_role,
      confirmed_at: Time.current,
      system_user: true
    )
    
    # Create user profile with just first name
    system_user.create_user_profile!(
      first_name: 'Bluesky',
      last_name: nil
    )
  end
  
  def down
    User.find_by(email: 'system@bluesky.internal')&.destroy
  end
end
```

### Step 3: Update User Model
Add helper methods and scopes for system user functionality.

**File**: `app/models/user.rb`

Add the following methods:
```ruby
# Class method to get the system user
def self.system
  find_by(system_user: true)
end

# Instance method to check if this is the system user
def system?
  system_user
end

# Override to ensure system user is always active
def active_for_authentication?
  return true if system?
  super
end

# Prevent system user from being deactivated
before_validation :prevent_system_user_deactivation, if: :system?

private

def prevent_system_user_deactivation
  if deactivated_at_changed? && deactivated_at.present?
    errors.add(:base, "System user cannot be deactivated")
    throw :abort
  end
end
```

### Step 4: Update Seeds File
Ensure system user is created in development/staging environments.

**File**: `db/seeds.rb`

Add at the beginning of the file:
```ruby
# Ensure system user exists
unless User.exists?(email: 'system@bluesky.internal')
  admin_role = Role.find_or_create_by(name: 'Administrator')
  
  system_user = User.create!(
    email: 'system@bluesky.internal',
    password: SecureRandom.hex(32),
    role: admin_role,
    confirmed_at: Time.current,
    system_user: true
  )
  
  system_user.create_user_profile!(
    first_name: 'Bluesky'
  )
  
  puts "Created Bluesky system user"
end
```

### Step 5: Update Automated Message Senders

#### 5.1 Lead Messaging Concern
**File**: `app/models/concerns/leads/messaging.rb`

Update all automated message methods to use system user:
- Line 296: `send_sms_optin_request` - Change `from: agent` to `from: User.system`
- Line 447: `send_initial_sms_response` - Change `from: agent` to `from: User.system`
- Line 482: `send_initial_email_response` - Change `from: agent` to `from: User.system`

#### 5.2 Engagement Policy
**File**: `app/models/concerns/leads/engagement_policy.rb`

Update the `send_rental_application` method:
- Line 41: Replace the agent check with:
```ruby
Message.new_message(
  body: rental_application_message,
  subject: rental_application_subject,
  from: User.system,
  to: self,
  medium: 'email',
  scheduled_action_id: scheduled_action&.id
).save
```

#### 5.3 Scheduled Action Notifications
**File**: `app/models/concerns/scheduled_actions/notification.rb`

Update notification sending:
- Line 43: Change `from: user` to `from: User.system`

### Step 6: Add System User Exclusions

#### 6.1 User Lists and Dropdowns
Update queries to exclude system user from normal user lists:
- Add scope to User model: `scope :non_system, -> { where(system_user: false) }`
- Update user selection dropdowns to use `User.non_system`

#### 6.2 User Policies
Update Pundit policies to prevent modification of system user:
- Add checks in UserPolicy to prevent edit/update/destroy of system users

### Step 7: Testing

1. **Unit Tests**
   - Test User.system returns the correct user
   - Test system user cannot be deactivated
   - Test system user is always active for authentication

2. **Integration Tests**
   - Test automated messages use system user as sender
   - Test system user appears correctly in message displays
   - Test system user is excluded from user lists

3. **Manual Testing**
   - Create a new lead and verify automated responses show "Bluesky" as sender
   - Check message history to confirm sender display
   - Verify system user cannot be edited in admin interface

## Rollback Plan

If issues arise:
1. Revert code changes
2. Run migration to remove system_user flag
3. Delete the system user record
4. Automated messages will fall back to using agent/property manager

## Deployment Steps

1. Deploy code changes
2. Run migrations
3. Run seeds to create system user (if not created by migration)
4. Verify system user exists and has correct attributes
5. Monitor automated message sending for any errors

## Success Criteria

- All automated messages show "Bluesky" as the sender
- System user cannot be modified or deleted through the UI
- No disruption to existing message functionality
- Clear distinction between human and system-generated messages