# BEM Audit Report: Leads Search Page

**Date:** January 2025  
**Page:** `/leads/search`  
**Status:** ❌ Non-compliant with BEM methodology

## Executive Summary

The leads search page uses a React-based implementation with CSS Modules that does not follow BEM naming conventions. This creates inconsistency with the rest of the v2 design system which follows strict BEM methodology.

## Files Contributing to Styling

### 1. View & Layout Files
| File | BEM Status | Notes |
|------|------------|-------|
| `/app/views/leads/search.html.erb` | ✅ Compliant | Minimal markup, just mounts React component |
| `/app/views/layouts/application_v2.html.erb` | ⚠️ Partial | Mix of BEM and legacy classes |

### 2. React Component Files (JavaScript/JSX)
| File | BEM Status | Current Naming |
|------|------------|----------------|
| `/app/javascript/lead_search/containers/LeadSearch.jsx` | ❌ Non-compliant | PascalCase |
| `/app/javascript/lead_search/containers/LeadSearchFilter.jsx` | ❌ Non-compliant | PascalCase |
| `/app/javascript/lead_search/components/LeadSearchLeads.jsx` | ❌ Non-compliant | PascalCase |
| `/app/javascript/lead_search/components/LeadSearchLead.jsx` | ❌ Non-compliant | PascalCase |
| `/app/javascript/lead_search/components/LeadSearchSidebar.jsx` | ❌ Non-compliant | PascalCase |
| `/app/javascript/lead_search/components/Pagination.jsx` | ❌ Non-compliant | Generic naming |

### 3. SCSS Files
| File | BEM Status | Issues |
|------|------------|--------|
| `/app/javascript/lead_search/containers/LeadSearch.scss` | ❌ Non-compliant | PascalCase `.LeadSearch` |
| `/app/javascript/lead_search/containers/LeadSearchFilter.scss` | ❌ Non-compliant | Mixed naming conventions |
| `/app/javascript/lead_search/components/LeadSearchLead.scss` | ❌ Non-compliant | PascalCase, camelCase mix |
| `/app/javascript/lead_search/components/LeadSearchSidebar.scss` | ❌ Non-compliant | PascalCase |
| `/app/assets/stylesheets/lead_search/LeadSearchFilter.scss` | ❌ Non-compliant | Duplicate file, different implementation |

### 4. Global Stylesheets
| File | BEM Status | Purpose |
|------|------------|---------|
| `/app/assets/stylesheets/application.css` | Mixed | Bootstrap 3 + legacy styles |
| `/app/assets/stylesheets/designv2.scss` | ✅ Compliant | V2 design system (BEM) |

## Major BEM Violations

### 1. Incorrect Naming Conventions

#### PascalCase (React Convention) Instead of kebab-case (BEM)
```scss
// ❌ Current
.LeadSearch { }
.LeadSearchFilter { }
.LeadSearchLead { }

// ✅ Should be
.lead-search { }
.lead-search-filter { }
.lead-search-lead { }
```

#### camelCase Instead of BEM Elements
```scss
// ❌ Current
.filterHeader { }
.filterSection { }
.leadName { }

// ✅ Should be
.lead-search-filter__header { }
.lead-search-filter__section { }
.lead-search-lead__name { }
```

#### Inconsistent Naming Within Same File
```scss
// From LeadSearchLead.scss - mixed conventions:
.LeadSearchLead { }      // PascalCase
.lead_priority { }       // snake_case
.contactInfo { }         // camelCase
```

### 2. Missing BEM Structure

#### No Clear Block Definition
```jsx
// ❌ Current - flat structure
<div className="filterSection">
  <div className="filterHeader">
  <div className="filterBody">

// ✅ Should be - BEM hierarchy
<div className="lead-search-filter__section">
  <div className="lead-search-filter__header">
  <div className="lead-search-filter__body">
```

#### Dynamic Classes Without BEM Modifiers
```jsx
// ❌ Current
className={`priority-${priority}`}
className={`state-${state}`}

// ✅ Should be
className={`lead-card--priority-${priority}`}
className={`lead-card--state-${state}`}
```

### 3. Bootstrap Dependencies

Heavy reliance on Bootstrap 3 classes throughout:
```jsx
<span className="glyphicon glyphicon-user" />
<button className="btn btn-primary">
<div className="form-group">
<input className="form-control">
```

### 4. ID-based Styling

Using IDs for styling instead of BEM classes:
```jsx
<div id="LeadSearch">
<div id="filters">
```

## Specific File Analysis

### LeadSearch.scss
```scss
// ❌ Current structure
.LeadSearch {
  .LeadSearchResults { }
  .loading { }
}

// ✅ BEM structure
.lead-search {
  &__results { }
  &__loading { }
}
```

### LeadSearchFilter.scss
```scss
// ❌ Current - multiple naming conventions
.LeadSearchFilter { }      // PascalCase
.filterHeader { }          // camelCase
.filter-section { }        // kebab-case
.show_advanced { }         // snake_case

// ✅ BEM structure
.lead-search-filter {
  &__header { }
  &__section { }
  &__toggle {
    &--advanced { }
  }
}
```

### LeadSearchLead.scss
```scss
// ❌ Current - grid areas without BEM
.LeadPriority { }
.LeadContact { }
.LeadProperty { }

// ✅ BEM structure
.lead-card {
  &__priority { }
  &__contact { }
  &__property { }
}
```

## Recommendations

### 1. Immediate Actions
1. Create a migration plan to convert all React components to BEM
2. Update CSS Modules configuration to support kebab-case
3. Create a style guide for React + BEM integration

### 2. Refactoring Priority
1. **High Priority**: LeadSearchFilter (most complex, most violations)
2. **Medium Priority**: LeadSearchLead (card components)
3. **Low Priority**: Pagination, Sidebar (smaller components)

### 3. Migration Strategy
```scss
// Step 1: Add BEM classes alongside existing
.LeadSearch,
.lead-search { }

// Step 2: Update React components
className="lead-search"

// Step 3: Remove old classes
.lead-search { }
```

### 4. Bootstrap Migration
- Replace `glyphicon` with v2 icon system
- Replace `btn` classes with v2 button components
- Replace `form-control` with v2 form components

## Conclusion

The leads search page requires a comprehensive refactor to align with the BEM methodology used throughout the v2 design system. The current implementation creates maintenance challenges and inconsistency in the codebase.

**Estimated effort**: 2-3 days for complete refactoring
**Risk level**: Medium (functional React app, needs careful testing)
**Business impact**: Low (visual changes should be minimal)