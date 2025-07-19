# Design v2 Migration Plan

## Overview
This document outlines the migration plan for making Design v2 the default UI for all BlueSky users, replacing the legacy v1 design.

## Changes Made

### 1. Feature Flag Configuration
**File:** `config/features.rb`
- Changed `design_v1` default from `true` to `false`
- Changed `design_v2` default from `true` to `false`
- Added "(Legacy)" label to v1 description

### 2. Application Controller
**File:** `app/controllers/application_controller.rb`
- Updated `versioned_layout` method to default to `application_v2` when no user preference is set
- Added comment explaining v2 is now the default

### 3. Migration Rake Tasks
**File:** `lib/tasks/migrate_users_to_v2.rake`

Created three rake tasks:

#### `users:migrate_to_v2`
- Migrates all users to design v2
- Enables design_v2 and disables design_v1 for each user
- Shows progress indicators ("+" for updated, "." for already migrated)
- Reports final statistics

#### `users:design_version_report`
- Reports current design version usage across all users
- Shows counts for v1, v2, and default users

#### `users:rollback_to_v1`
- Emergency rollback to v1 for all users
- Requires confirmation before proceeding

## Migration Process

### Stage 1: Staging Deployment
1. Deploy code changes to staging environment
2. Run design version report:
   ```bash
   heroku run bundle exec rake users:design_version_report -a druid-staging
   ```
3. Test v2 design with a few test accounts
4. Migrate all staging users:
   ```bash
   heroku run bundle exec rake users:migrate_to_v2 -a druid-staging
   ```
5. Monitor for issues for 24-48 hours

### Stage 2: Production Deployment
1. Deploy code changes to production
2. Run design version report to document current state:
   ```bash
   heroku run bundle exec rake users:design_version_report -a druid-prod
   ```
3. Migrate users in batches (optional - the rake task handles all users):
   ```bash
   heroku run bundle exec rake users:migrate_to_v2 -a druid-prod
   ```
4. Monitor error logs and user feedback

### Stage 3: Post-Migration
1. Monitor application performance metrics
2. Check for increased error rates
3. Gather user feedback via support channels
4. Address any UI/UX issues that arise

## Rollback Plan

If critical issues are discovered:

1. **Quick Rollback** - Revert all users to v1:
   ```bash
   heroku run bundle exec rake users:rollback_to_v1 -a druid-prod
   ```

2. **Feature Flag Rollback** - Change defaults back in `config/features.rb`:
   ```ruby
   feature :design_v1, default: true, description: 'UI v1 Navigation'
   feature :design_v2, default: false, description: 'UI v2 with modern design system'
   ```

3. **Individual User Rollback** - Admin can change specific users via Flipflop dashboard at `/flipflop`

## Success Metrics

- [ ] All users successfully migrated to v2
- [ ] No increase in error rates post-migration
- [ ] No significant performance degradation
- [ ] Positive or neutral user feedback

## Timeline

- **Week 1**: Staging deployment and testing
- **Week 2**: Production deployment for internal users
- **Week 3**: Full production rollout
- **Week 4**: Post-migration monitoring and optimization

## Notes

- The Flipflop gem allows individual user preferences to override system defaults
- Users can still access v1 if explicitly enabled by an admin
- The migration is non-destructive - user data and preferences (other than design version) remain unchanged
- Support ticket modal and other v2-specific features will now be available to all users

## Related Files

- `/app/assets/stylesheets/v2/` - All v2-specific styles
- `/app/views/layouts/application_v2.html.erb` - V2 layout template
- `/app/views/shared/_navbar_v2.html.erb` - V2 navigation
- `/plans/ui-v2-implementation.md` - Original implementation plan