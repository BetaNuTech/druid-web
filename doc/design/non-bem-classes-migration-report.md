# Non-BEM Classes Migration Report

## Summary

A comprehensive scan of the `app/views` directory reveals extensive use of non-BEM classes that need migration. This includes Bootstrap classes, custom classes with underscores, and ID selectors that should be converted to BEM classes.

### Statistics
- **458** instances of classes with underscores (non-BEM naming)
- **23** instances of Bootstrap component classes
- **10** instances of Bootstrap background color classes
- Multiple ID selectors that should be classes

## 1. Bootstrap Classes That Need Migration

### Panel Components
Found in:
- `scheduled_actions/index.html.erb` - Uses `well` class
- `marketing_sources/index.html.erb` - Uses `well` class
- `marketing_sources/_marketing_source.html.erb` - Uses `well` class (line 1)

### Alert Components
Found in:
- `messages/index.html.erb` - Uses alert classes (alert-success, alert-danger, etc.)

### Form Components
Found in **43 files** using form-group, form-control, form-inline:
- Major areas: leads, properties, users, teams, messages, scheduled_actions
- Example files:
  - `leads/_form.html.erb`
  - `properties/_form_*.html.erb` (multiple form partials)
  - `users/_form.html.erb`
  - `messages/_form.html.erb`

### Grid System (row, col-*)
Found in **50+ files** - Pervasive throughout the application:
- All major index pages
- All form pages
- Dashboard views
- Show pages

### Text Alignment Classes
Found in **19 files** using text-center, text-left, text-right:
- Index pages for most resources
- `shared/_notifications.html.erb`
- `scheduled_actions/completion_form.html.erb`

### Badge Classes
Found in **10 files**:
- `home/_stats.html.erb`
- `home/_my_property_leads.html.erb`
- `leads/_duplicates_v2.html.erb`
- `leads/show.html.erb`
- `marketing_sources/show.html.erb`

### Label Classes
Found in **50+ files** using label, label-default, label-primary, etc.:
- Form labels throughout the application
- Status indicators in various views

### Modal Components
Found in:
- `shared/_navbar_v2.html.erb` - Uses modal classes

### Other Bootstrap Classes
- `pull-left`, `pull-right` in `leads/_messages.html.erb`
- `bg-danger` and other background classes in 10 files

## 2. Custom Classes with Underscores (Non-BEM)

### Major Patterns Found:

#### Lead-related Classes
- `lead_listing` (table class)
- `lead_row__actions`, `lead_row__content` (partial BEM but inconsistent)
- References to `lead_card` partial (but using proper partial rendering)

#### Section Components (Partial BEM)
- `section-header__content`
- `section-header__icon`
- `section-header__title`
- `section-header__count`
- `section-header__actions`
- `section__content`
- `empty-state__icon`

#### Marketing Source Classes
- `marketing_source--stats--table` (incorrect BEM syntax - should use single hyphens)

#### Calendar/Schedule Classes
- `scheduled_action_calendar_day` (underscores instead of hyphens)
- `scheduled_action_calendar_entry` (underscores instead of hyphens)

#### Other Notable Classes
- Various form-related classes with underscores
- Property selection related classes
- Navigation related classes

## 3. ID Selectors That Should Be Classes

Found in layout files:
- `#footer` - Used in:
  - `layouts/application.html.erb`
  - `layouts/application_v1.html.erb`
  - `layouts/application_v2.html.erb`
- `#sidebar` - Used in:
  - `shared/_navbar_v1.html.erb`
  - `shared/_navbar_v2.html.erb`

## 4. Priority Areas for Migration

### High Priority (Most Used)
1. **Grid System** - Replace all Bootstrap grid classes with BEM grid system
2. **Form Components** - Migrate form-group, form-control to BEM equivalents
3. **Text Utilities** - Replace text-center, text-left, text-right

### Medium Priority
1. **Panel/Well Components** - Convert to BEM card components
2. **Badge/Label Classes** - Convert to BEM badge/label components
3. **Marketing Source Tables** - Fix incorrect BEM syntax

### Low Priority
1. **Modal Components** - Limited usage
2. **Alert Components** - Limited usage
3. **ID to Class Conversions** - Layout-specific, manageable scope

## 5. Recommended Migration Approach

1. **Create BEM Equivalents** for all Bootstrap components
2. **Establish Naming Conventions**:
   - Replace underscores with hyphens in custom classes
   - Fix incorrect BEM syntax (-- should be used for modifiers, not elements)
   - Convert IDs to classes where appropriate
3. **Migrate by Component Type** rather than by file to ensure consistency
4. **Update Partials** that render these components to use new classes
5. **Test Thoroughly** as many of these classes likely have associated JavaScript

## 6. Special Considerations

- The `lead_card`, `task_card`, and `message_card` references appear to be partial names, not CSS classes
- Some classes like `section-header__*` already follow BEM but are inconsistently applied
- The marketing source stats table uses incorrect BEM syntax with double hyphens for elements
- Many forms will need comprehensive updates as they heavily rely on Bootstrap form classes