# Bluesky UI v2 Implementation Plan

## Overview
This document outlines the implementation of a new visual design system (v2) for the Bluesky Lead Management application. The v2 design will modernize the interface using the company's brand colors and Montserrat typography while maintaining backward compatibility through the existing feature flag system.

## Brand Identity

### Colors
- **Deep Blue**: #005089
- **Medium Blue**: #0070B9  
- **Light Blue**: #6EA9DB
- **Teal**: #00AFA8
- **Dark Gray**: #58585A
- **Light Gray**: #BCBEBE

### Typography
- **Font Family**: Montserrat (Google Font)
- **Weights**: 
  - Light (300)
  - Regular (400)
  - Medium (500)
  - Bold (700)

### Google Fonts Integration
```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Montserrat:ital,wght@0,100..900;1,100..900&display=swap" rel="stylesheet">
```

## Current System Analysis

### Versioning Infrastructure
- **Feature Flags**: Flipflop gem with UserPreferenceStrategy
- **Per-User Control**: Individual feature toggles via `/flipflop` route
- **Layout Selection**: `versioned_layout` method in ApplicationController
- **File Structure**:
  - Layouts: `application.html.erb` (v0), `application_v1.html.erb`
  - Stylesheets: `designv0.scss`, `designv1.scss`
  - Style directories: `v0/`, `v1/` with parallel file structures
  - Partials: Versioned navbar partials

## Implementation Phases

### Phase 1: Infrastructure Setup
1. **Add design_v2 feature flag**
   - File: `config/features.rb`
   - Default: false (safe rollout)
   - Description: 'UI v2 with modern design system'

2. **Update versioned_layout method**
   - File: `app/controllers/application_controller.rb`
   - Logic: Check design_v2 → design_v1 → default
   
3. **Create v2 layout**
   - File: `app/views/layouts/application_v2.html.erb`
   - Include Montserrat font
   - Reference designv2 stylesheet

4. **Create stylesheet manifest**
   - File: `app/assets/stylesheets/designv2.scss`
   - Require v2 directory tree

### Phase 2: Core Styles

#### Variables (`v2/variables.scss`)
```scss
// Brand Colors
$brand-deep-blue: #005089;
$brand-medium-blue: #0070B9;
$brand-light-blue: #6EA9DB;
$brand-teal: #00AFA8;
$brand-dark-gray: #58585A;
$brand-light-gray: #BCBEBE;

// Semantic Colors
$primary: $brand-medium-blue;
$secondary: $brand-teal;
$success: #28a745;
$warning: #FFA500;
$danger: #DC3545;

// Typography
$font-family-primary: 'Montserrat', -apple-system, sans-serif;
$font-weight-light: 300;
$font-weight-regular: 400;
$font-weight-medium: 500;
$font-weight-bold: 700;

// Spacing (8px base unit)
$spacing-xs: 4px;
$spacing-sm: 8px;
$spacing-md: 16px;
$spacing-lg: 24px;
$spacing-xl: 32px;

// Shadows
$shadow-sm: 0 1px 2px rgba(0,0,0,0.1);
$shadow-md: 0 2px 4px rgba(0,0,0,0.1);
$shadow-lg: 0 4px 8px rgba(0,0,0,0.1);

// Transitions
$transition-base: all 0.2s ease;
```

### Phase 3: Component Updates

#### Navigation Updates
- **Header**: Gradient from deep blue to medium blue
- **Sidebar**: 
  - Background: white
  - Text: dark gray
  - Hover: light blue background
  - Active: teal left border

#### Button Styles
- **Primary**: Medium blue background, white text
- **Secondary**: Teal background, white text  
- **Danger**: Red (#DC3545) for destructive actions
- **Hover states**: 10% darker shade
- **All buttons**: Montserrat Medium (500) weight

#### Lead Cards
- White background with subtle shadow
- Left border color-coded by status:
  - Open/New: Teal (#00AFA8)
  - In Progress: Medium blue (#0070B9)
  - Scheduled: Light blue (#6EA9DB)
  - Urgent: Red (#DC3545)
- Hover effect: Elevated shadow

#### Forms
- Input borders: Light gray (#BCBEBE)
- Focus state: Medium blue border with glow
- Labels: Montserrat Medium, dark gray
- Error states: Red border and text

### Phase 4: Page-Specific Updates

#### Dashboard
- Section headers with icon accent color (medium blue)
- Card-based layout for lead listings
- Improved spacing using 8px grid

#### Tables
- Alternating row colors using subtle gray
- Hover state: Light blue background
- Better action button alignment

#### Calendar
- Updated date cell styling
- Color-coded events using brand palette
- Improved readability

### Phase 5: Testing & Rollout

#### Testing Strategy
1. Enable for internal team first
2. Use `/flipflop` interface to toggle per user
3. Gather feedback and iterate
4. Expand to beta users
5. Monitor for issues

#### Rollout Plan
1. Deploy with design_v2 flag disabled
2. Enable for QA and internal testing
3. Gradual rollout to user segments
4. Full deployment when stable
5. Maintain v1 for rollback capability

## File Structure

```
app/
├── assets/
│   └── stylesheets/
│       ├── designv2.scss (new)
│       └── v2/ (new)
│           ├── variables.scss
│           ├── site.scss
│           ├── navigation.scss
│           ├── buttons.scss
│           ├── forms.scss
│           ├── cards.scss
│           ├── home.scss
│           ├── leads.scss
│           ├── properties.scss
│           ├── messages.scss
│           ├── scheduled_actions.scss
│           └── [other component files]
├── controllers/
│   └── application_controller.rb (modify)
└── views/
    ├── layouts/
    │   └── application_v2.html.erb (new)
    └── shared/
        └── _navbar_v2.html.erb (new)
```

## Development Guidelines

### CSS Best Practices
- Use SCSS variables for all colors
- Follow 8px spacing grid
- Maintain consistent transitions
- Mobile-first responsive design
- Avoid !important declarations

### Testing Checklist
- [ ] Cross-browser compatibility
- [ ] Mobile responsiveness
- [ ] Accessibility (contrast ratios)
- [ ] Performance (no render blocking)
- [ ] Feature flag toggling
- [ ] User preference persistence

### Incremental Development
1. Start with global styles (variables, typography)
2. Update navigation and layout
3. Modernize buttons and forms
4. Redesign page-specific components
5. Polish with transitions and hover states

## Success Metrics
- Improved visual consistency
- Better user feedback on modern design
- No degradation in performance
- Smooth rollout with no breaking changes
- Easy rollback capability if needed

## Notes
- Keep v1 styles intact for rollback
- Document any Bootstrap overrides
- Test thoroughly with existing JavaScript
- Consider dark mode for future phase