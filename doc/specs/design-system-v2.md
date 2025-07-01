# BlueSky Design System V2 - BEM Edition

## Table of Contents
1. [Overview](#overview)
2. [BEM Architecture](#bem-architecture)
3. [Color System](#color-system)
4. [Typography](#typography)
5. [Component Library](#component-library)
6. [Layout System](#layout-system)
7. [Utility Classes](#utility-classes)
8. [Page Components](#page-components)
9. [Migration Guide](#migration-guide)
10. [Best Practices](#best-practices)

## Overview

This document defines the BlueSky Design System V2 with BEM (Block Element Modifier) methodology. The system has been fully migrated to use consistent naming conventions, organized file structure, and reusable components that maintain backward compatibility with existing HTML.

### Design Principles
- **Clarity**: Information should be immediately understandable
- **Consistency**: Similar elements behave similarly across the application
- **Efficiency**: Common tasks should be easily discoverable and quick to complete
- **Accessibility**: All users should be able to effectively use the application
- **Modern**: Contemporary design that feels fresh yet professional

### File Organization
```
app/assets/stylesheets/v2/
├── base/                    # Foundation styles
│   ├── _reset.scss         # CSS reset/normalize
│   ├── _typography.scss    # Typography rules
│   └── _global.scss        # Global styles
├── components/             # BEM components
│   ├── _badges.scss        # Status badges and labels
│   ├── _breadcrumbs.scss   # State flow breadcrumbs
│   ├── _buttons.scss       # Button variants
│   ├── _buttons-compat.scss # Bootstrap 3 compatibility
│   ├── _cards.scss         # Card patterns (3 designs)
│   ├── _empty-states.scss  # Empty state patterns
│   ├── _footer.scss        # Footer component
│   ├── _forms.scss         # Form elements and layouts
│   ├── _icons.scss         # Icon styling and enhancements
│   ├── _messages.scss      # Message components
│   ├── _modals.scss        # Modal dialogs
│   ├── _navigation.scss    # Header and sidebar navigation
│   ├── _property-selection.scss # Property selector
│   ├── _section-headers.scss # Section header patterns
│   ├── _selectize.scss     # Selectize.js customization
│   ├── _tables.scss        # Table styling
│   └── _tasks.scss         # Task card components
├── pages/                  # Page-specific styles
│   ├── calendar/          # Calendar view
│   ├── comments/          # Comments section
│   ├── duplicates/        # Duplicate detection
│   ├── home/              # Dashboard
│   ├── leads/             # Lead pages
│   ├── message-templates/ # Message templates
│   ├── messages/          # Messages (future)
│   ├── notes/             # Notes section
│   ├── properties/        # Properties management
│   ├── roommates/         # Roommates
│   ├── tasks/             # Tasks (future)
│   ├── teams/             # Teams management
│   ├── timeline/          # Activity timeline
│   ├── units/             # Units listing
│   └── users/             # Users management
├── utilities/              # Utility classes
│   ├── _animations.scss    # Animation keyframes
│   ├── _colors.scss        # Color utilities
│   ├── _display.scss       # Display utilities
│   └── _spacing.scss       # Spacing utilities
├── _variables.scss         # Design tokens
├── _functions.scss         # Mixins and functions
└── main.scss              # Main import file
```

## BEM Architecture

### Naming Convention

BEM (Block Element Modifier) provides a consistent naming structure:

- **Block**: The main component (`card`, `button`, `navigation`)
- **Element**: A child component (`card__header`, `button__icon`)
- **Modifier**: A variation (`card--primary`, `button--large`)

### Correct BEM Usage

```scss
// ✅ CORRECT
.card { }                    // Block
.card__header { }           // Element
.card__body { }             // Element
.card--primary { }          // Modifier
.card__header--large { }    // Element with modifier

// ❌ INCORRECT
.card__header__title { }    // Never use double elements
.card-header { }            // Use double underscore for elements
.card_primary { }           // Use double hyphen for modifiers
```

### Legacy Support

All components maintain backward compatibility:

```scss
// New BEM structure
.property-selector { }
.property-selector__label { }
.property-selector__select { }

// Legacy support (automatically mapped)
#propertyselection--container { @extend .property-selector; }
#propertyselection--selector { @extend .property-selector__select; }
```

## Color System

### Brand Colors

```scss
// Core Brand Palette
$brand-deep-blue: #005089;     // Primary headers, emphasis
$brand-medium-blue: #0070B9;   // Primary actions, links
$brand-light-blue: #6EA9DB;    // Hover states, accents
$brand-teal: #00AFA8;          // Information, incoming comms
$brand-dark-gray: #58585A;     // Body text
$brand-light-gray: #BCBEBE;    // Disabled states

// Semantic Assignments
$primary: $brand-medium-blue;  // Primary actions, outgoing messages
$secondary: $brand-teal;        // Secondary actions, incoming messages
$success: #28a745;             // Completed, positive states
$warning: #FFA500;             // Warnings, duplicates
$danger: #DC3545;              // Errors, urgent (fire icons!)
$info: #17A2B8;                // Informational states
```

### Neutral Colors

```scss
$white: #FFFFFF;
$gray-50: #FAFBFC;   // Section headers, subtle backgrounds
$gray-100: #F8F9FA;  // Light backgrounds
$gray-200: #E9ECEF;  // Borders
$gray-300: #DEE2E6;  // Dividers
$gray-400: #CED4DA;  // Disabled borders
$gray-500: #ADB5BD;  // Muted text
$gray-600: #6C757D;  // Secondary text
$gray-700: #495057;  // Body text
$gray-800: #343A40;  // Primary text
$gray-900: #212529;  // Headers
$black: #000000;
```

## Typography

### Font Configuration

```scss
$font-family-primary: 'Montserrat', -apple-system, BlinkMacSystemFont, 
                      "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;

// Font Weights
$font-weight-light: 300;      // Rarely used
$font-weight-regular: 400;    // Body text
$font-weight-medium: 500;     // Subtitles, emphasis
$font-weight-semi-bold: 600;  // Headers, buttons
$font-weight-bold: 700;       // Primary headers

// Font Sizes
$font-size-xs: 12px;    // Labels, metadata
$font-size-sm: 13px;    // Secondary text
$font-size-base: 14px;  // Body text
$font-size-lg: 16px;    // Subtitles
$font-size-xl: 20px;    // Section headers
$font-size-2xl: 24px;   // Page headers
$font-size-3xl: 32px;   // Hero headers
$font-size-4xl: 42px;   // Large hero headers

// Heading Sizes (aliases)
$font-size-h1: $font-size-4xl;
$font-size-h2: $font-size-3xl;
$font-size-h3: $font-size-2xl;
$font-size-h4: $font-size-xl;
$font-size-h5: $font-size-lg;
$font-size-h6: $font-size-base;
```

## Component Library

### Cards (`components/_cards.scss`)

Three distinct card designs for different use cases:

#### Card Design 1: Non-Actionable/Read-Only
```scss
.card {
  @include card($padding: $spacing-lg, $shadow-level: 1);
  
  &--info {
    // Read-only information display
    cursor: default;
    
    &:hover {
      transform: translateY(-2px);
      box-shadow: 0 4px 16px rgba(0, 0, 0, 0.08);
    }
  }
}
```

#### Card Design 2: Editable/Clickable
```scss
.card--editable {
  border: 2px solid transparent;
  cursor: pointer;
  
  &:hover {
    border-color: $primary;
    box-shadow: 0 4px 12px rgba($primary, 0.15);
  }
}
```

#### Card Design 3: Status Cards with Accent
```scss
.card--status {
  @include status-indicator($primary, 'left', 4px);
  padding-left: $spacing-lg;
  
  // Color variants
  &--primary { @include status-indicator($primary); }
  &--success { @include status-indicator($success); }
  &--warning { @include status-indicator($warning); }
  &--danger { @include status-indicator($danger); }
  &--info { @include status-indicator($info); }
}
```

### Buttons (`components/_buttons.scss`)

All buttons follow the gradient pattern with hover lift:

```scss
.btn {
  @include button-base;
  
  &--primary {
    @include button-variant($primary);
  }
  
  &--secondary {
    background: $gray-100;
    color: $gray-700;
    
    &:hover {
      background: $gray-200;
      color: $gray-900;
    }
  }
  
  &--success {
    @include button-variant($success);
  }
  
  &--danger {
    @include button-variant($danger);
  }
  
  // Size modifiers
  &--small {
    padding: $spacing-xs $spacing-sm;
    font-size: $font-size-sm;
  }
  
  &--large {
    padding: $spacing-md $spacing-lg;
    font-size: $font-size-lg;
  }
}
```

### Navigation (`components/_navigation.scss`)

Header and sidebar with mobile support:

```scss
.header {
  position: fixed;
  top: 0;
  height: 50px;
  background: linear-gradient(135deg, $brand-deep-blue 0%, $primary 100%);
  
  &__brand {
    display: flex;
    align-items: baseline;
  }
  
  &__hamburger {
    &--mobile {
      display: block;
      @media (min-width: $screen-md-min) {
        display: none;
      }
    }
  }
}

.sidebar {
  position: fixed;
  top: 50px;
  width: 250px;
  
  &__item {
    padding: $spacing-sm $spacing-lg;
    
    &--active {
      background: rgba($brand-teal, 0.08);
      color: $brand-teal;
      
      &::before {
        content: '';
        position: absolute;
        left: 0;
        width: 4px;
        background: $brand-teal;
      }
    }
  }
}
```

### Messages (`components/_messages.scss`)

Comprehensive message components:

```scss
.message-card {
  @include card($padding: $spacing-md);
  
  &--incoming {
    border-left: 4px solid $brand-teal;
    
    .message-card__avatar {
      background: linear-gradient(135deg, $brand-teal 0%, darken($brand-teal, 10%) 100%);
    }
  }
  
  &--outgoing {
    border-left: 4px solid $primary;
    
    .message-card__avatar {
      background: linear-gradient(135deg, $primary 0%, darken($primary, 10%) 100%);
    }
  }
  
  &--unread {
    border-left: 4px solid $primary;
    background: rgba($primary, 0.02);
  }
}
```

### Icons (`components/_icons.scss`)

Enhanced icon system with guaranteed fire icon colors:

```scss
.icon {
  display: inline-block;
  line-height: 1;
  
  // Size modifiers
  &--xs { font-size: 12px; }
  &--sm { font-size: 14px; }
  &--md { font-size: 16px; }
  &--lg { font-size: 20px; }
  &--xl { font-size: 24px; }
  
  // Color modifiers
  &--primary { color: $primary; }
  &--danger { color: $danger; }
  &--success { color: $success; }
}

// Special fire icon enhancement
.glyphicon-fire {
  color: $danger !important;
  text-shadow: 0 0 3px rgba($danger, 0.5);
  animation: flicker 2s ease-in-out infinite;
}

// Priority markers
.priority-marker {
  &--high {
    .glyphicon-fire {
      &:nth-child(1) { animation-delay: 0s; }
      &:nth-child(2) { animation-delay: 0.3s; }
      &:nth-child(3) { animation-delay: 0.6s; }
    }
  }
}
```

### Section Headers (`components/_section-headers.scss`)

Consistent section headers with proper BEM:

```scss
.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: $spacing-lg;
  background: linear-gradient(135deg, $gray-50 0%, $gray-100 100%);
  border-bottom: 2px solid $gray-200;
  margin: 0; // Fills to edges
  
  &__title {
    font-size: $font-size-xl;
    font-weight: $font-weight-semi-bold;
    color: $gray-900;
    margin: 0;
  }
  
  &__count {
    background: $gray-200;
    color: $gray-700;
    padding: 2px 8px;
    border-radius: 12px;
    font-size: $font-size-sm;
  }
  
  &__actions {
    display: flex;
    gap: $spacing-sm;
  }
}
```

## Layout System

### Spacing Scale

```scss
$spacing-xs: 4px;    // Inline elements
$spacing-sm: 8px;    // Related elements
$spacing-md: 16px;   // Card sections
$spacing-lg: 24px;   // Between cards
$spacing-xl: 32px;   // Between sections
$spacing-2xl: 48px;  // Major sections
```

### Grid System

Responsive breakpoints:

```scss
$screen-xs-min: 480px;
$screen-sm-min: 768px;
$screen-md-min: 992px;
$screen-lg-min: 1200px;

// Max widths (one less than next breakpoint)
$screen-xs-max: ($screen-sm-min - 1);
$screen-sm-max: ($screen-md-min - 1);
$screen-md-max: ($screen-lg-min - 1);
```

### Border Radius

```scss
$border-radius-xs: 2px;   // Very small elements
$border-radius-sm: 3px;   // Small elements  
$border-radius-md: 5px;   // Cards, sections, buttons
$border-radius-lg: 8px;   // Modals, larger elements
```

## Utility Classes

### Spacing Utilities (`utilities/_spacing.scss`)

```scss
// Margin utilities
.m-0 { margin: 0 !important; }
.m-1 { margin: $spacing-xs !important; }
.m-2 { margin: $spacing-sm !important; }
.m-3 { margin: $spacing-md !important; }
.m-4 { margin: $spacing-lg !important; }
.m-5 { margin: $spacing-xl !important; }
.m-6 { margin: $spacing-2xl !important; }

// Directional margins
.mt-3 { margin-top: $spacing-md !important; }
.mb-3 { margin-bottom: $spacing-md !important; }
.ml-3 { margin-left: $spacing-md !important; }
.mr-3 { margin-right: $spacing-md !important; }
.mx-3 { margin-left: $spacing-md !important; margin-right: $spacing-md !important; }
.my-3 { margin-top: $spacing-md !important; margin-bottom: $spacing-md !important; }

// Padding follows same pattern
.p-3 { padding: $spacing-md !important; }
.px-3 { padding-left: $spacing-md !important; padding-right: $spacing-md !important; }
```

### Color Utilities (`utilities/_colors.scss`)

```scss
// Text colors
.text-primary { color: $primary !important; }
.text-secondary { color: $secondary !important; }
.text-success { color: $success !important; }
.text-danger { color: $danger !important; }
.text-warning { color: $warning !important; }
.text-info { color: $info !important; }
.text-muted { color: $gray-600 !important; }

// Background colors
.bg-primary { background-color: $primary !important; }
.bg-light { background-color: $gray-100 !important; }
.bg-white { background-color: $white !important; }

// Gradient backgrounds
.bg-gradient-primary {
  background: linear-gradient(135deg, $primary 0%, darken($primary, 10%) 100%) !important;
}
```

### Display Utilities (`utilities/_display.scss`)

```scss
// Display properties
.d-none { display: none !important; }
.d-block { display: block !important; }
.d-inline-block { display: inline-block !important; }
.d-flex { display: flex !important; }
.d-inline-flex { display: inline-flex !important; }

// Flexbox utilities
.flex-row { flex-direction: row !important; }
.flex-column { flex-direction: column !important; }
.justify-content-start { justify-content: flex-start !important; }
.justify-content-center { justify-content: center !important; }
.justify-content-between { justify-content: space-between !important; }
.align-items-center { align-items: center !important; }

// Responsive display
@media (min-width: $screen-md-min) {
  .d-md-block { display: block !important; }
  .d-md-none { display: none !important; }
}
```

### Animation Utilities (`utilities/_animations.scss`)

```scss
// Animation classes
.animate--pulse { animation: pulse 2s ease-in-out infinite; }
.animate--flicker { animation: flicker 2s ease-in-out infinite; }
.animate--fadeIn { animation: fadeIn 0.3s ease-out; }
.animate--spin { animation: spin 1s linear infinite; }

// Animation delays
.delay--100 { animation-delay: 100ms; }
.delay--200 { animation-delay: 200ms; }
.delay--300 { animation-delay: 300ms; }
```

## Page Components

### Dashboard (`pages/home/_dashboard.scss`)

```scss
.dashboard {
  &__row {
    @include make-row();
    margin-bottom: $spacing-xl;
  }
  
  &__col {
    @include make-col-ready();
    
    &--main {
      @include make-col(8);
      @media (max-width: $screen-md-max) {
        @include make-col(12);
      }
    }
    
    &--sidebar {
      @include make-col(4);
      @media (max-width: $screen-md-max) {
        @include make-col(12);
      }
    }
  }
}
```

### Calendar (`pages/calendar/_index.scss`)

```scss
.calendar {
  background: $white;
  border-radius: $border-radius-lg;
  
  &__header {
    background: linear-gradient(135deg, $primary 0%, darken($primary, 10%) 100%);
    color: $white;
    padding: $spacing-lg;
  }
  
  &__table {
    width: 100%;
    
    td {
      border: 1px solid $gray-200;
      height: 100px;
      vertical-align: top;
      
      @media (max-width: $screen-sm-max) {
        height: 80px;
      }
    }
  }
  
  &__entry {
    &--overdue {
      background: $danger;
      color: $white;
    }
  }
}
```

### Timeline (`pages/timeline/_index.scss`)

```scss
.timeline {
  &__list {
    position: relative;
    
    &::before {
      content: '';
      position: absolute;
      left: 20px;
      top: 0;
      bottom: 0;
      width: 2px;
      background: $gray-200;
    }
  }
  
  &__item {
    padding-left: 50px;
    margin-bottom: $spacing-lg;
    
    &::before {
      content: '';
      position: absolute;
      left: 14px;
      width: 12px;
      height: 12px;
      background: $white;
      border: 2px solid $primary;
      border-radius: 50%;
    }
    
    &--state-change::before {
      border-color: $success;
      background: $success;
    }
  }
}
```

## Migration Guide

### Converting Old Classes to BEM

#### Example 1: Lead Card
```html
<!-- Old -->
<div class="lead_card" style="margin-bottom: 20px;">
  <div class="lead_header">John Doe</div>
  <div class="lead_content">Content here</div>
</div>

<!-- New BEM -->
<div class="card card--status card--status-teal mb-4">
  <div class="card__header">
    <h3 class="card__title">John Doe</h3>
  </div>
  <div class="card__body">Content here</div>
</div>
```

#### Example 2: Section Header
```html
<!-- Old -->
<div id="tasks-header" class="dashboard__section__header">
  <h3>Tasks Due Today</h3>
</div>

<!-- New BEM -->
<div class="section-header">
  <h3 class="section-header__title">
    Tasks Due Today
    <span class="section-header__count">5</span>
  </h3>
  <div class="section-header__actions">
    <button class="btn btn--primary btn--small">View All</button>
  </div>
</div>
```

#### Example 3: Navigation Item
```html
<!-- Old -->
<li class="sidebar--item active">
  <a href="/home">
    <i class="glyphicon glyphicon-home"></i> Home
  </a>
</li>

<!-- New BEM -->
<li class="sidebar__item sidebar__item--active">
  <a href="/home" class="sidebar__link">
    <i class="sidebar__icon glyphicon glyphicon-home"></i>
    <span class="sidebar__text">Home</span>
  </a>
</li>
```

### Using Mixins

The design system provides powerful mixins for consistency:

```scss
// Card with status
.my-custom-card {
  @include card($padding: $spacing-lg);
  @include status-indicator($brand-teal, 'left', 4px);
  @include hover-lift;
}

// Custom button
.my-custom-button {
  @include button-base;
  @include button-variant($brand-teal);
  @include focus-visible;
}

// Responsive layout
.my-layout {
  @include container;
  
  @include mobile {
    padding: $spacing-sm;
  }
  
  @include desktop {
    padding: $spacing-xl;
  }
}
```

## Best Practices

### 1. Always Use BEM

```scss
// ✅ Good
.message-card { }
.message-card__header { }
.message-card--unread { }

// ❌ Bad
.message_card { }
.message-card-header { }
.messageCard { }
```

### 2. Avoid Deep Nesting

```scss
// ✅ Good - Max 3 levels
.card {
  &__header {
    color: $gray-900;
  }
  
  &--primary {
    border-color: $primary;
  }
}

// ❌ Bad - Too deep
.card {
  .header {
    .title {
      .icon {
        color: $primary;
      }
    }
  }
}
```

### 3. Use Design Tokens

```scss
// ✅ Good
.alert {
  padding: $spacing-md;
  border-radius: $border-radius-md;
  color: $gray-700;
}

// ❌ Bad
.alert {
  padding: 16px;
  border-radius: 5px;
  color: #495057;
}
```

### 4. Leverage Utilities

```html
<!-- ✅ Good - Use utilities for spacing -->
<div class="card mb-3">
  <div class="card__header px-4 py-3">
    Title
  </div>
</div>

<!-- ❌ Bad - Custom styles for common patterns -->
<div class="card" style="margin-bottom: 16px;">
  <div class="card__header" style="padding: 16px 24px;">
    Title
  </div>
</div>
```

### 5. Mobile First

```scss
// ✅ Good - Mobile first
.sidebar {
  width: 100%;
  
  @media (min-width: $screen-md-min) {
    width: 250px;
  }
}

// ❌ Bad - Desktop first
.sidebar {
  width: 250px;
  
  @media (max-width: $screen-sm-max) {
    width: 100%;
  }
}
```

### 6. Semantic Colors

```scss
// ✅ Good - Use semantic variables
.message--incoming {
  border-color: $secondary; // $brand-teal
}

.action-button {
  background: $primary; // $brand-medium-blue
}

// ❌ Bad - Use color directly
.message--incoming {
  border-color: #00AFA8;
}

.action-button {
  background: #0070B9;
}
```

### 7. Component Composition

```html
<!-- ✅ Good - Compose with utilities -->
<div class="card card--status card--status-primary mb-3">
  <div class="card__header d-flex justify-content-between align-items-center">
    <h3 class="card__title">Task</h3>
    <div class="card__actions">
      <button class="btn btn--icon btn--sm">
        <i class="glyphicon glyphicon-edit"></i>
      </button>
    </div>
  </div>
</div>

<!-- ❌ Bad - Everything custom -->
<div class="custom-task-card">
  <div class="custom-task-header">
    <!-- Custom everything -->
  </div>
</div>
```

## Component Reference

### Quick Component List

- **Badges**: `.badge`, `.badge--success`, `.badge--warning`
- **Breadcrumbs**: `.breadcrumbs`, `.breadcrumbs__item`, `.breadcrumbs__link`
- **Buttons**: `.btn`, `.btn--primary`, `.btn--secondary`, `.btn--danger`
- **Cards**: `.card`, `.card--info`, `.card--editable`, `.card--status`
- **Empty States**: `.empty-state`, `.empty-state__icon`, `.empty-state__text`
- **Forms**: `.form-group`, `.form-control`, `.form-label`
- **Icons**: `.icon`, `.icon--primary`, `.icon--lg`, `.glyphicon-fire`
- **Messages**: `.message-card`, `.message-card--incoming`, `.message-card--unread`
- **Modals**: `.modal`, `.modal__dialog`, `.modal__content`
- **Navigation**: `.header`, `.sidebar`, `.sidebar__item`
- **Section Headers**: `.section-header`, `.section-header__title`
- **Tables**: `.table`, `.table__header`, `.table__row`
- **Tasks**: `.task-card`, `.task-card__priority`, `.task-card__actions`

### Common Patterns

#### Status Cards with Actions
```html
<div class="card card--status card--status-primary">
  <div class="card__header">
    <h3 class="card__title">Task Title</h3>
    <span class="badge badge--warning">Due Soon</span>
  </div>
  <div class="card__body">
    <p class="text-muted">Task description here...</p>
  </div>
  <div class="card__footer">
    <div class="card__actions">
      <button class="btn btn--success btn--sm">
        <i class="glyphicon glyphicon-ok"></i> Complete
      </button>
      <button class="btn btn--primary btn--sm">
        <i class="glyphicon glyphicon-edit"></i> Edit
      </button>
    </div>
  </div>
</div>
```

#### Message with Avatar
```html
<div class="message-card message-card--incoming message-card--unread">
  <div class="message-card__indicators">
    <div class="message-card__avatar">
      <i class="glyphicon glyphicon-user"></i>
    </div>
    <span class="message-type message-type--sms">
      <i class="message-type__icon glyphicon glyphicon-phone"></i>
      SMS
    </span>
  </div>
  <div class="message-card__content">
    <div class="message-card__header">
      <h4 class="message-card__subject">New Message</h4>
      <span class="message-timestamp">
        <i class="message-timestamp__icon glyphicon glyphicon-time"></i>
        5 mins ago
      </span>
    </div>
    <div class="message-card__body">
      Message content here...
    </div>
  </div>
</div>
```

## Conclusion

The BlueSky Design System V2 with BEM provides a robust, maintainable foundation for UI development. By following these guidelines and using the provided components, developers can create consistent, accessible, and beautiful interfaces that enhance the user experience while maintaining code quality.

Remember:
- Use BEM naming consistently
- Leverage existing components and utilities
- Follow the color and typography guidelines
- Test on mobile devices
- Maintain backward compatibility during migration

For questions or updates to this design system, please submit a pull request with proposed changes and rationale.