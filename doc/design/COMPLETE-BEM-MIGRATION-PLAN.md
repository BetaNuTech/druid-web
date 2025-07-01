# Complete BEM Migration Plan - Beyond Buttons

## Overview
This document outlines the comprehensive migration plan for all non-BEM classes to BEM, covering all components beyond buttons.

## Current State Analysis

### Statistics
- **458** instances of classes with underscores (non-BEM naming)
- **50+** files using Bootstrap grid system
- **43** files using Bootstrap form classes
- **23** instances of Bootstrap component classes
- **10** instances of Bootstrap background classes

### What We Have (V2 BEM Components)
✅ Forms, Tables, Cards, Badges, Buttons, Navigation, Modals
✅ Typography utilities, Spacing utilities, Display utilities
✅ Message cards, Tasks, Section headers, Empty states

### What We're Missing
✅ ~~Grid system~~ - CREATED in `_grid.scss` with Bootstrap compatibility
✅ ~~Alert component~~ - CREATED in `_alerts.scss` with Bootstrap compatibility
✅ ~~Well/Panel component~~ - ADDED to `_cards.scss` as `.card--panel`
✅ ~~Label component~~ - CREATED in `_labels.scss` with Bootstrap compatibility
✅ ~~Float utilities~~ - CREATED in `_layout.scss` with `.float--left/right`
✅ ~~Background color utilities~~ - ADDED to `_colors.scss` as `.bg--*`

## Migration Phases

### Phase 1: Create Missing Core Components ✅ COMPLETE

#### 1.1 Grid System Component ✅ DONE
**Status**: Created with full Bootstrap compatibility

Created `app/assets/stylesheets/v2/components/_grid.scss`:
```scss
// BEM Grid System to replace Bootstrap grid
.grid {
  &__container {
    // Container variants
    &--fluid { }
    &--fixed { }
  }
  
  &__row {
    // Row styling
  }
  
  &__col {
    // Column base
    &--12, &--11, &--10, &--9, &--8, &--7, &--6, &--5, &--4, &--3, &--2, &--1 { }
    &--sm-*, &--md-*, &--lg-*, &--xl-* { }
    &--offset-* { }
  }
}
```

Files to update:
- All index pages
- All form pages  
- Dashboard views
- Show pages

#### 1.2 Alert Component ✅ DONE
**Status**: Created with Bootstrap mappings

Created `app/assets/stylesheets/v2/components/_alerts.scss`:
```scss
.alert {
  // Base alert styles
  
  &--success { }
  &--danger { }
  &--warning { }
  &--info { }
  
  &__icon { }
  &__content { }
  &__close { }
}
```

Files to update:
- `messages/index.html.erb`
- Various forms with validation messages

#### 1.3 Panel/Well Component ✅ DONE
**Status**: Extended card component with `.card--panel`

Implemented:
- Added `.card--panel` variant to `_cards.scss`
- Added `.well` compatibility mapping

Files to update:
- `scheduled_actions/index.html.erb`
- `marketing_sources/index.html.erb`
- `marketing_sources/_marketing_source.html.erb`

### Phase 2: Fix Non-BEM Custom Classes

#### 2.1 Classes with Underscores
Convert all underscore classes to proper BEM:

| Current | Should Be |
|---------|-----------|
| `lead_listing` | `lead-listing` or `table--leads` |
| `scheduled_action_calendar_day` | `calendar__day` |
| `scheduled_action_calendar_entry` | `calendar__entry` |
| `marketing_source--stats--table` | `marketing-source__stats-table` |

#### 2.2 Partial BEM Implementation
Fix components that started BEM but aren't consistent:
- `section-header__*` - Already BEM but needs consistency check
- `lead_row__*` - Convert underscores in block name

### Phase 3: Update Utility Classes

#### 3.1 Text Alignment (19 files)
Map Bootstrap to BEM utilities:
- `text-center` → Keep as-is (already in typography utilities)
- `text-left` → Keep as-is
- `text-right` → Keep as-is

#### 3.2 Float Utilities
Add to `app/assets/stylesheets/v2/utilities/_layout.scss`:
- `pull-left` → `.float--left`
- `pull-right` → `.float--right`

#### 3.3 Background Colors
Add to `app/assets/stylesheets/v2/utilities/_colors.scss`:
- `bg-danger` → `.bg--danger`
- `bg-success` → `.bg--success`
- etc.

### Phase 4: Convert ID Selectors to Classes

#### 4.1 Layout IDs
- `#footer` → `.footer`
- `#sidebar` → `.sidebar`
- `#header` → `.header`

Files:
- All layout files in `app/views/layouts/`
- Navbar partials

### Phase 5: Form System Migration

#### 5.1 Form Structure
The V2 already has form components, but need to ensure all forms use them:
- Verify `.form-group`, `.form-control` usage
- Update any custom form styling to BEM

Priority forms:
- Lead forms (most complex)
- Property forms
- User/Team forms

## Implementation Strategy

### Step 1: Component Creation (Week 1)
1. Create grid system component
2. Create alert component  
3. Extend card component for panels
4. Add missing utilities

### Step 2: High-Traffic Views (Week 2)
1. Update all lead views with new grid
2. Update message views with alerts
3. Update dashboard with new grid

### Step 3: Forms Migration (Week 3)
1. Lead forms
2. Property forms
3. All other forms

### Step 4: Remaining Views (Week 4)
1. Admin views
2. Marketing views
3. Settings/configuration views

## Testing Checklist

For each migrated component:
- [ ] Visual appearance matches original
- [ ] Responsive behavior maintained
- [ ] JavaScript functionality intact
- [ ] No console errors
- [ ] Accessibility preserved

## Success Metrics

1. **Zero Bootstrap Classes**: No `col-*`, `row`, `alert-*`, etc.
2. **Consistent BEM**: All classes follow `block__element--modifier`
3. **No Underscores**: Except in BEM element names
4. **No IDs for Styling**: Only classes for CSS
5. **Complete Documentation**: All new components documented

## Quick Reference - Class Mappings

### Grid System
```
<div class="row">                    → <div class="grid__row">
<div class="col-md-6">              → <div class="grid__col grid__col--md-6">
<div class="container">             → <div class="grid__container">
<div class="container-fluid">       → <div class="grid__container grid__container--fluid">
```

### Components
```
<div class="alert alert-success">   → <div class="alert alert--success">
<div class="well">                  → <div class="panel">
<span class="label label-primary">  → <span class="label label--primary">
<div class="panel panel-default">   → <div class="card card--panel">
```

### Utilities
```
<div class="pull-left">             → <div class="float--left">
<div class="pull-right">            → <div class="float--right">
<div class="bg-danger">             → <div class="bg--danger">
<div class="text-center">           → <div class="text-center"> (no change)
```

## Next Immediate Actions

1. **Create Grid Component** - Most critical, blocks everything else
2. **Create Alert Component** - Needed for user feedback
3. **Update High-Traffic Lead Views** - Biggest impact
4. **Fix Marketing Source BEM** - Quick win, wrong syntax

---

**Created**: <%= Date.today %>
**Scope**: 458 non-BEM classes across 100+ files
**Priority**: Critical - Inconsistent styling hurts UX
**Estimated Timeline**: 4 weeks for complete migration