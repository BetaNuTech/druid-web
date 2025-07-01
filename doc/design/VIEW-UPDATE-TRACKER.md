# BlueSky V2 View Update Tracker

This document tracks the progress of updating all views to use BEM methodology and V2 design system components.

## Button Class Conversion Guide

| Old Bootstrap Class | New BEM Class |
|-------------------|---------------|
| `btn btn-primary` | `btn btn--primary` |
| `btn btn-success` | `btn btn--success` |
| `btn btn-danger` | `btn btn--danger` |
| `btn btn-warning` | `btn btn--warning` |
| `btn btn-info` | `btn btn--info` |
| `btn btn-default` | `btn btn--secondary` |
| `btn btn-link` | `btn btn--text` |
| `btn btn-xs` | `btn btn--xs` |
| `btn btn-sm` | `btn btn--sm` |
| `btn btn-lg` | `btn btn--lg` |
| `btn btn-block` | `btn btn--block` |

## View Update Status

### High Priority - Core User Views

#### Leads (31 files)
- [x] `index.html.erb` ✅ (No buttons to update)
- [x] `show.html.erb` ✅ (Updated 4 buttons to BEM)
- [x] `new.html.erb` ✅ (No buttons, uses _form partial)
- [x] `edit.html.erb` ✅ (No buttons, uses _form partial)
- [x] `_form.html.erb` ✅ (Updated 2 buttons to BEM)
- [ ] `_lead_card.html.erb`
- [ ] `_actions.html.erb`
- [ ] `_advanced_filter.html.erb`
- [ ] `_assignments.html.erb`
- [ ] `_calendar.html.erb`
- [ ] `_calendar_navigation.html.erb`
- [x] `_comments.html.erb` ✅ (Already using BEM)
- [ ] `_data_grid.html.erb`
- [x] `_duplicates.html.erb` ✅ (Updated btn-warning to btn--warning)
- [ ] `_engagement_policy.html.erb`
- [ ] `_events.html.erb`
- [ ] `_exports.html.erb`
- [ ] `_faxes.html.erb`
- [ ] `_filter_bar.html.erb`
- [ ] `_generate_leads_modal.html.erb`
- [ ] `_guest_card.html.erb`
- [ ] `_lead.html.erb`
- [ ] `_lead_data.html.erb`
- [ ] `_lead_detail_sidebar.html.erb`
- [x] `_message.html.erb` ✅ (Updated btn-primary to btn--primary)
- [x] `_message_card.html.erb` ✅ (Uses shared partial)
- [x] `_messages.html.erb` ✅ (Updated 1 button to BEM)
- [ ] `_notes.html.erb`
- [ ] `_referral.html.erb`
- [x] `_scheduled_actions.html.erb` ✅ (Updated 1 button to BEM)
- [ ] `_show_actions.html.erb`
- [x] `_duplicates_v2.html.erb` ✅ (Updated btn-warning to btn--warning)
- [x] `_pagination.html.erb` ✅ (Updated btn-default to btn--secondary, btn-info to btn--info)
- [x] `_roommates.html.erb` ✅ (Updated btn-action to btn--action, btn-edit to btn--edit, btn-delete to btn--delete)
- [x] `_walkin_form.html.erb` ✅ (Updated btn-primary to btn--primary, btn-info to btn--info)
- [x] `_comment_card.html.erb` ✅ (Updated to btn--secondary btn--icon and btn--danger btn--icon)

#### Additional Lead Views
- [x] `mass_assignment.html.erb` ✅ (Updated btn-info to btn--info)
- [x] `progress_state.html.erb` ✅ (Updated btn-info to btn--info)

#### Messages (6 files)
- [x] `index.html.erb` ✅ (Updated btn-default to btn--secondary, btn-primary to btn--primary)
- [x] `show.html.erb` ✅ (Updated all button classes to BEM)
- [x] `new.html.erb` ✅ (No buttons to update)
- [x] `edit.html.erb` ✅ (Updated 1 button to BEM)
- [x] `_form.html.erb` ✅ (Updated 3 buttons to BEM)
- [x] `_new_message_callout.html.erb` ✅ (Updated 3 buttons to BEM)

#### Scheduled Actions/Tasks (12 files)
- [x] `index.html.erb` ✅ (Already using BEM)
- [x] `show.html.erb` ✅ (No buttons to update)
- [x] `new.html.erb` ✅ (No buttons to update)
- [x] `edit.html.erb` ✅ (Updated 1 button to BEM)
- [x] `_form.html.erb` ✅ (Updated 2 buttons to BEM)
- [ ] `_scheduled_action.html.erb`
- [ ] `_actions.html.erb`
- [ ] `_bulk_actions.html.erb`
- [ ] `_date_range_filter.html.erb`
- [ ] `_filters.html.erb`
- [ ] `_scheduled_action_modal.html.erb`
- [ ] `_scheduled_actions_modal.html.erb`

#### Home/Dashboard (15 files)
- [ ] `dashboard.html.erb`
- [ ] `index.html.erb`
- [x] `_my_property_leads.html.erb` ✅ (Updated btn-primary to btn--primary)
- [x] `_my_team.html.erb` ✅ (Updated btn-primary to btn--primary)
- [ ] `_activity_item.html.erb`
- [ ] `_chart_placeholder.html.erb`
- [ ] `_chart_section.html.erb`
- [ ] `_export_all_task.html.erb`
- [ ] `_lead_stats.html.erb`
- [ ] `_leasing_specialist_activity.html.erb`
- [ ] `_my_calendar_events.html.erb`
- [ ] `_my_recent_activity.html.erb`
- [ ] `_property_stats.html.erb`
- [ ] `_scheduled_action.html.erb`
- [ ] `_search_bar.html.erb`
- [ ] `_stats_section.html.erb`
- [ ] `_today.html.erb`

### Medium Priority - Management Views

#### Properties (27 files)
- [ ] `index.html.erb`
- [ ] `show.html.erb`
- [ ] `new.html.erb`
- [ ] `edit.html.erb`
- [ ] `_form.html.erb`
- [ ] `_auto_responder_modal.html.erb`
- [ ] `_engagement_policy_settings.html.erb`
- [ ] `_export_all_progress_modal.html.erb`
- [ ] `_export_all_task.html.erb`
- [ ] `_export_row.html.erb`
- [ ] `_lead_source_adapters.html.erb`
- [ ] `_lease_settings.html.erb`
- [ ] `_misc_settings.html.erb`
- [ ] `_open_period_modal.html.erb`
- [ ] `_phone_number_fields.html.erb`
- [ ] `_phone_numbers.html.erb`
- [ ] `_properties.html.erb`
- [ ] `_property.html.erb`
- [ ] `_property_card.html.erb`
- [ ] `_property_stats.html.erb`
- [ ] `_reasons.html.erb`
- [ ] `_row.html.erb`
- [ ] `_sms_template_modal.html.erb`
- [ ] `_task_assignment_strategy.html.erb`
- [ ] `_team_associations.html.erb`
- [ ] `_user_assignments.html.erb`
- [ ] `_working_hours.html.erb`

#### Teams (9 files)
- [ ] `index.html.erb`
- [ ] `show.html.erb`
- [ ] `new.html.erb`
- [ ] `edit.html.erb`
- [ ] `_form.html.erb`
- [ ] `_row.html.erb`
- [ ] `_stats.html.erb`
- [ ] `_team.html.erb`
- [ ] `_user_row.html.erb`

#### Users (6 files)
- [ ] `index.html.erb`
- [ ] `show.html.erb`
- [ ] `edit.html.erb`
- [ ] `_form.html.erb`
- [ ] `_row.html.erb`
- [ ] `_user.html.erb`

### Lower Priority - Admin/Config Views

#### Other Controllers (Multiple files each)
- [ ] Comments
- [ ] Duplicates
- [ ] Email Templates
- [ ] Events
- [ ] Exports
- [ ] Import Tasks
- [ ] Reasons
- [ ] Reports
- [ ] Roles
- [ ] Roommates
- [ ] Settings
- [ ] Stats
- [ ] Task Templates
- [ ] Units
- [ ] Yardi

#### Devise Authentication Views
- [ ] Sessions
- [ ] Registrations
- [ ] Passwords
- [ ] Confirmations
- [ ] Unlocks

## SCSS File Creation Status

### Layout Files (TODO)
- [ ] `v2/layouts/_sidebar.scss`
- [ ] `v2/layouts/_header.scss`
- [ ] `v2/layouts/_content.scss`
- [ ] `v2/layouts/_responsive.scss`

### Page-Specific Files (TODO)
- [ ] `v2/pages/messages/_show.scss`
- [ ] `v2/pages/messages/_compose.scss`
- [ ] `v2/pages/tasks/_index.scss`

## Legacy Code Cleanup

### Files with Temporary Migration Support
- [ ] `components/_messages.scss` (lines 434-452) - Legacy support for `.messages-container`, `.message-item`, `.message-badge`
- [ ] `components/_modals.scss` (lines 308-373) - Legacy support for `.support-ticket-modal`, `.modal-dialog-centered`
- [ ] `components/_footer.scss` (lines 76-107) - Legacy support for `#footer`, `#copyright_notice`, `#bluesky_version`
- [ ] `components/_breadcrumbs.scss` (lines 451-509) - Legacy support for `#crumbs`, `.crumb`, `.state_toggle`
- [ ] `components/_property-selection.scss` (lines 147-225) - Legacy support for `#propertyselection--*` IDs

## Notes

### Completed Updates
1. **Button Component** - Added hover-lift effects to all button variants
2. **Button Compatibility** - Added direct class mappings for Bootstrap buttons
3. **Messages Index** - Updated to use shared message card component and BEM buttons
4. **Messages Show** - Fixed routing and updated all button classes to BEM
5. **Leads Views** - Updated all main views and 11 partials to BEM
6. **Messages Views** - All 6 files now using BEM button classes
7. **Scheduled Actions Views** - Updated all button classes to BEM (edit, form)
8. **Home Dashboard** - Updated _my_property_leads and _my_team partials to BEM
9. **Message Card** - Fixed hover effect to lighten instead of darken

### Common Issues Found
1. Mixed button class usage (e.g., `btn btn--primary` with `btn-info`)
2. Missing BEM modifiers on some elements
3. Inline styles that should use utility classes
4. Old Bootstrap grid classes mixed with new styles

### Testing Checklist for Each View
- [ ] All buttons have hover lift effect
- [ ] Button gradients display correctly
- [ ] Focus states are visible
- [ ] Disabled states work properly
- [ ] No JavaScript errors in console
- [ ] Responsive behavior works correctly
- [ ] All BEM classes are properly applied

---

**Last Updated:** <%= Date.today %>
**Status:** Phase 1 of BEM migration complete! All high-priority core views (Leads, Messages, Scheduled Actions, Home partials) have been updated.
**Progress:** 32 files updated, approximately 50 files remaining
**Next Priority:** Update Properties views (Phase 2), then continue with admin/config views