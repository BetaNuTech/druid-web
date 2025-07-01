# Leads Show Page - Partials BEM Analysis

This document analyzes all partials rendered in `app/views/leads/show.html.erb` for BEM compliance.

## Overview

The leads show page renders 8 main partials, each with varying levels of BEM compliance. Below is a detailed analysis of each partial.

## Partial Analysis

### 1. `_state_toggle.html.erb` (Line 79)

**BEM Compliance Status:** ❌ Not BEM compliant

**Non-BEM Classes:**
- `state_toggle` - Should be `state-toggle`
- `crumbs` - Not descriptive, should be part of state-toggle component
- `crumb` - Should be `state-toggle__crumb`
- `crumb-link` - Should be `state-toggle__link`
- `crumb-active` - Should be `state-toggle__link--active`
- `crumb-inactive` - Should be `state-toggle__link--inactive`
- `crumb-isolated` - Should be modifier
- `state_toggle-agent` - Inconsistent naming (underscore + hyphen)
- `nowrap` - Utility class, not BEM

**Bootstrap Grid Classes:** 
- `row`
- `col-md-12`

**Already BEM Compliant:** None

### 2. `_scheduled_actions.html.erb` (Line 131)

**BEM Compliance Status:** ✅ Mostly BEM compliant

**Non-BEM Classes:**
- `tasks-section` - Already follows BEM structure
- `section-header` - Generic, could be `tasks-section__header`
- `header-actions` - Could be `tasks-section__actions`
- `tasks-container` - Could be `tasks-section__container`
- `empty-tasks` - Could be `tasks-section__empty`
- `empty-icon` - Could be `tasks-section__empty-icon`
- `tasks-list` - Could be `tasks-section__list`
- `pending-tasks` - Modifier, could be `tasks-section__list--pending`
- `completed-tasks` - Modifier, could be `tasks-section__list--completed`

**Bootstrap Grid Classes:** None

**Already BEM Compliant:**
- `btn--primary`
- `btn--secondary`

### 3. `_scheduled_action.html.erb` (Rendered within _scheduled_actions.html.erb)

**BEM Compliance Status:** ✅ Fully BEM compliant

**Non-BEM Classes:** None - this file uses proper BEM notation throughout

**Already BEM Compliant:**
- `card`
- `card--clickable`
- `card--status`
- `card--status-success`
- `card--status-primary`
- `card__body`
- `card__task-layout`
- `card__icon`
- `card__icon--primary`
- `card__details`
- `card__meta`
- `card__title`
- `card__description`
- `card__actions`
- `btn--success`
- `btn--icon`
- `btn--secondary`

### 4. `_source_document.html.erb` (Line 383)

**BEM Compliance Status:** ❌ Not BEM compliant

**Non-BEM Classes:**
- `source-email-section` - BEM block, good
- `section-header` - Generic, should be `source-email-section__header`
- `source-email-container` - Should be `source-email-section__container`
- `email-preview-container` - Should be `source-email-section__preview-container`
- `email-preview-wrapper` - Should be `source-email-section__preview-wrapper`
- `email-preview-frame` - Should be `source-email-section__preview-frame`
- `toggle-text` - Generic, should be component-specific

**Bootstrap Grid Classes:** None

**Already BEM Compliant:**
- `btn--primary`

### 5. `_duplicate_listing.html.erb` (Line 394)

**BEM Compliance Status:** ❌ Not BEM compliant

**Non-BEM Classes:**
- `duplicates-section` - BEM block, good
- `section-header` - Generic, should be `duplicates-section__header`
- `duplicate-count` - Should be `duplicates-section__count`
- `duplicates-container` - Should be `duplicates-section__container`

**Bootstrap Grid Classes:** None

**Already BEM Compliant:** None

### 6. `_duplicates_v2.html.erb` (Rendered within _duplicate_listing.html.erb)

**BEM Compliance Status:** ❌ Not BEM compliant

**Non-BEM Classes:**
- `duplicates-list` - Should be part of parent component
- `duplicate-group` - Should be `duplicates-list__group`
- `group-header` - Should be `duplicates-list__group-header`
- `group-toggle-btn` - Should be `duplicates-list__toggle`
- `group-count` - Should be `duplicates-list__count`
- `group-content` - Should be `duplicates-list__content`
- `duplicate-card` - Should be `duplicates-list__card`
- `primary-lead` - Modifier, should be `duplicates-list__card--primary`
- `secondary-lead` - Modifier, should be `duplicates-list__card--secondary`
- `current-lead` - Modifier, should be `duplicates-list__card--current`
- `clickable` - Utility class, not BEM
- `duplicate-header` - Should be `duplicates-list__card-header`
- `lead-info` - Should be `duplicates-list__lead-info`
- `lead-avatar` - Should be `duplicates-list__avatar`
- `lead-details` - Should be `duplicates-list__details`
- `lead-name` - Should be `duplicates-list__name`
- `current-badge` - Should be `duplicates-list__badge`
- `lead-meta` - Should be `duplicates-list__meta`
- `lead-state` - Should be `duplicates-list__state`
- `lead-created` - Should be `duplicates-list__created`
- `duplicate-actions` - Should be `duplicates-list__actions`
- `duplicate-body` - Should be `duplicates-list__body`
- `duplicate-fields` - Should be `duplicates-list__fields`
- `field-item` - Should be `duplicates-list__field`
- `match-highlight` - Modifier, should be `duplicates-list__field--match`
- `field-icon` - Should be `duplicates-list__field-icon`
- `field-content` - Should be `duplicates-list__field-content`
- `field-label` - Should be `duplicates-list__field-label`
- `field-value` - Should be `duplicates-list__field-value`
- `match-indicators` - Should be `duplicates-list__matches`
- `match-label` - Should be `duplicates-list__match-label`
- `match-badge` - Should be `duplicates-list__match-badge`

**Bootstrap Grid Classes:** None

**Already BEM Compliant:**
- `btn--small`
- `btn--warning`

### 7. `_roommates.html.erb` (Line 399)

**BEM Compliance Status:** ❌ Not BEM compliant

**Non-BEM Classes:**
- `roommates-section` - BEM block, good
- `section-header` - Generic, should be `roommates-section__header`
- `roommates-container` - Should be `roommates-section__container`
- `roommates-list` - Should be `roommates-section__list`
- `roommate-card` - Should be `roommates-section__card`
- `roommate-main` - Should be `roommates-section__main`
- `roommate-identity` - Should be `roommates-section__identity`
- `roommate-avatar` - Should be `roommates-section__avatar`
- `roommate-info` - Should be `roommates-section__info`
- `roommate-name` - Should be `roommates-section__name`
- `roommate-status` - Should be `roommates-section__status`
- `status-badge` - Generic, should be `roommates-section__badge`
- `roommate-actions` - Should be `roommates-section__actions`
- `roommate-details` - Should be `roommates-section__details`
- `roommate-contact` - Should be `roommates-section__contact`
- `contact-item` - Should be `roommates-section__contact-item`
- `contact-allowed` - Modifier, should be `roommates-section__contact-item--allowed`
- `contact-icon` - Should be `roommates-section__contact-icon`
- `contact-info` - Should be `roommates-section__contact-info`
- `contact-value` - Should be `roommates-section__contact-value`
- `contact-badge` - Should be `roommates-section__contact-badge`
- `allowed` - Modifier, should be `roommates-section__contact-badge--allowed`
- `not-allowed` - Modifier, should be `roommates-section__contact-badge--not-allowed`
- `no-contact` - Should be `roommates-section__no-contact`
- `roommate-notes` - Should be `roommates-section__notes`
- `notes-label` - Should be `roommates-section__notes-label`
- `notes-content` - Should be `roommates-section__notes-content`
- `empty-roommates` - Should be `roommates-section__empty`
- `empty-icon` - Should be `roommates-section__empty-icon`
- `text-muted` - Bootstrap utility class

**Bootstrap Grid Classes:** None

**Already BEM Compliant:**
- `btn--primary`
- `btn--action`
- `btn--edit`
- `btn--delete`

### 8. `_comments.html.erb` (Line 404)

**BEM Compliance Status:** ❌ Not BEM compliant

**Non-BEM Classes:**
- `comments-section` - BEM block, good
- `section-header` - Generic, should be `comments-section__header`
- `comment-form-wrapper` - Should be `comments-section__form-wrapper`
- `comments-container` - Should be `comments-section__container`
- `empty-comments` - Should be `comments-section__empty`
- `empty-icon` - Should be `comments-section__empty-icon`
- `comments-list` - Should be `comments-section__list`
- `show-more-wrapper` - Should be `comments-section__more-wrapper`
- `text-muted` - Bootstrap utility class

**Bootstrap Grid Classes:** None

**Already BEM Compliant:**
- `btn--primary`
- `btn--default`
- `btn--small`

### 9. `_comment_card.html.erb` (Rendered within _comments.html.erb)

**BEM Compliance Status:** ❌ Not BEM compliant

**Non-BEM Classes:**
- `comment-card` - BEM block, good
- `has-action` - Modifier, should be `comment-card--has-action`
- `comment-header` - Should be `comment-card__header`
- `comment-meta` - Should be `comment-card__meta`
- `comment-author` - Should be `comment-card__author`
- `author-avatar` - Should be `comment-card__avatar`
- `author-details` - Should be `comment-card__author-details`
- `author-name` - Should be `comment-card__author-name`
- `comment-timestamp` - Should be `comment-card__timestamp`
- `edited-tag` - Should be `comment-card__edited`
- `comment-actions` - Should be `comment-card__actions`
- `comment-content` - Should be `comment-card__content`
- `comment-action-tag` - Should be `comment-card__action-tag`
- `action-icon` - Should be `comment-card__action-icon`
- `action-text` - Should be `comment-card__action-text`
- `comment-text` - Should be `comment-card__text`
- `comment-message-info` - Should be `comment-card__message-info`
- `message-type-icon` - Should be `comment-card__message-icon`
- `message-label` - Should be `comment-card__message-label`

**Bootstrap Grid Classes:** None

**Already BEM Compliant:**
- `btn--secondary`
- `btn--icon`
- `btn--danger`

### 10. `_messages.html.erb` (Line 409)

**BEM Compliance Status:** ❌ Not BEM compliant

**Non-BEM Classes:**
- `messages-section` - BEM block, good
- `section-header` - Generic, should be `messages-section__header`
- `header-actions` - Should be `messages-section__actions`
- `message-alerts` - Should be `messages-section__alerts`
- `messages-container` - Should be `messages-section__container`
- `messages-list` - Should be `messages-section__list`
- `empty-messages` - Should be `messages-section__empty`
- `empty-icon` - Should be `messages-section__empty-icon`
- `roommate-messages-section` - Should be nested BEM component
- `roommate-header` - Should be `messages-section__roommate-header`
- `text-muted` - Bootstrap utility class
- `pull-right` - Bootstrap utility class

**Bootstrap Grid Classes:** None

**Already BEM Compliant:**
- `alert--warning`
- `alert--info`
- `btn--sm`
- `btn--primary`

### 11. `_timeline.html.erb` (Line 414)

**BEM Compliance Status:** ❌ Not BEM compliant

**Non-BEM Classes:**
- `timeline-section` - BEM block, good
- `section-header` - Generic, should be `timeline-section__header`
- `toggle-text` - Generic, should be `timeline-section__toggle-text`
- `timeline-container` - Should be `timeline-section__container`
- `empty-timeline` - Should be `timeline-section__empty`
- `empty-icon` - Should be `timeline-section__empty-icon`
- `timeline-list` - Should be `timeline-section__list`
- `text-muted` - Bootstrap utility class

**Bootstrap Grid Classes:** None

**Already BEM Compliant:**
- `btn--primary`

### 12. `_timeline_card.html.erb` (Rendered within _timeline.html.erb)

**BEM Compliance Status:** ❌ Not BEM compliant

**Non-BEM Classes:**
- `timeline-card` - BEM block, good
- `timeline-content` - Should be `timeline-card__content`
- `timeline-header` - Should be `timeline-card__header`
- `timeline-meta` - Should be `timeline-card__meta`
- `action-type` - Should be `timeline-card__action`
- `timeline-timestamp` - Should be `timeline-card__timestamp`
- `timeline-user` - Should be `timeline-card__user`
- `timeline-body` - Should be `timeline-card__body`
- `timeline-related` - Should be `timeline-card__related`
- `related-label` - Should be `timeline-card__related-label`

**Bootstrap Grid Classes:** None

**Already BEM Compliant:** None

## Summary

### BEM Compliance by Partial:

1. ✅ **Fully Compliant:** `_scheduled_action.html.erb`
2. ✅ **Mostly Compliant:** `_scheduled_actions.html.erb`
3. ❌ **Not Compliant:** All other partials (10 out of 12)

### Common Issues:

1. **Generic class names** like `section-header`, `empty-icon`, `toggle-text` used across multiple components
2. **Inconsistent naming** mixing underscores and hyphens (e.g., `state_toggle-agent`)
3. **Modifier classes** not following BEM convention (e.g., `has-action` instead of `--has-action`)
4. **Deeply nested elements** not properly namespaced to their block
5. **Bootstrap utility classes** mixed with BEM classes (`text-muted`, `pull-right`, `nowrap`)

### Recommendations:

1. **Establish component boundaries** - Each partial should be a clear BEM block
2. **Namespace all elements** to their parent block
3. **Use consistent naming** - hyphens only, no underscores
4. **Extract common patterns** into reusable BEM components
5. **Keep Bootstrap grid classes** but ensure semantic BEM classes exist alongside
6. **Create a shared component library** for common patterns like empty states, section headers