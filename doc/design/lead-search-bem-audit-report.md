# Lead Search Page BEM Audit Report

## Executive Summary

The `/leads/search` page has a **mixed implementation** combining some BEM methodology with legacy class naming conventions. While some files show attempts at BEM naming, there's inconsistent application across the codebase, with significant mixing of methodologies.

## Files Contributing to Lead Search Styling

### 1. Main View File
- **File**: `/app/views/leads/search.html.erb`
- **Status**: ✅ BEM Compliant (minimal markup)
- **Notes**: Only contains a React mount point `<div id="LeadSearch"></div>`

### 2. Layout File
- **File**: `/app/views/layouts/application_v2.html.erb`
- **Status**: ⚠️ Partially BEM Compliant
- **BEM Classes Found**:
  - `header__appname`
  - `header__hamburger`
  - `header__hamburger--mobile`
  - `header__brand-primary`
  - `header__brand-secondary`
- **Non-BEM Classes Found**:
  - `header` (should be a block)
  - `content`
  - `#app_layout`, `#headerrow`, `#content`, `#viewcontent`, `#footer` (IDs instead of classes)

### 3. React Component Files

#### LeadSearch.jsx (Main Container)
- **File**: `/app/javascript/lead_search/containers/LeadSearch.jsx`
- **SCSS**: `/app/javascript/lead_search/containers/LeadSearch.scss`
- **Status**: ❌ Not BEM Compliant
- **Classes Used**:
  - `LeadSearch` (PascalCase, not BEM)
  - `Header` (PascalCase, not BEM)
- **Should Be**:
  - `lead-search` (block)
  - `lead-search__header` (element)

#### LeadSearchFilter.jsx
- **File**: `/app/javascript/lead_search/containers/LeadSearchFilter.jsx`
- **SCSS**: `/app/javascript/lead_search/containers/LeadSearchFilter.scss`
- **Status**: ❌ Not BEM Compliant
- **Classes Used**:
  - `LeadSearchFilter` (PascalCase)
  - `filterHeader`, `filterTitleSection`, `filterIconWrapper`
  - `filterActions`, `searchControls`, `filterBody`
  - `filtersContainer`, `dateFilters`, `filterGrid`
  - `filterSummary`
- **Also imports**: `/app/javascript/lead_search/components/LeadSearchFilter.scss` with duplicate/conflicting styles
- **Should Be**:
  - `lead-search-filter` (block)
  - `lead-search-filter__header`
  - `lead-search-filter__title-section`
  - etc.

#### LeadSearchLeads.jsx
- **File**: `/app/javascript/lead_search/components/LeadSearchLeads.jsx`
- **SCSS**: `/app/javascript/lead_search/components/LeadSearchLeads.scss`
- **Status**: ❌ Not BEM Compliant
- **Classes Used**:
  - `LeadSearchLeads` (PascalCase)
  - `ResultsTableHeader`
  - `ResultsTable`
- **Should Be**:
  - `lead-list` (block)
  - `lead-list__header`
  - `lead-list__table`

#### LeadSearchLead.jsx (Individual Lead Card)
- **File**: `/app/javascript/lead_search/components/LeadSearchLead.jsx`
- **SCSS**: `/app/javascript/lead_search/components/LeadSearchLead.scss`
- **Status**: ❌ Not BEM Compliant
- **Classes Used**:
  - `LeadSearchLead` (PascalCase)
  - `priority`, `contact`, `property`, `preferences`, `notes`
  - `lead_name`, `contact_info`, `lead_notes`, `vip_icon`
  - Bootstrap classes: `glyphicon`, `glyphicon-*`
  - Dynamic classes: `priority-${priority}`, `state-${state}`
- **Should Be**:
  - `lead-card` (block)
  - `lead-card__priority-section`
  - `lead-card__contact`
  - `lead-card__name`
  - `lead-card__icon--vip`
  - etc.

#### LeadSearchSidebar.jsx
- **File**: `/app/javascript/lead_search/components/LeadSearchSidebar.jsx`
- **SCSS**: `/app/javascript/lead_search/components/LeadSearchSidebar.scss`
- **Status**: ❌ Not BEM Compliant
- **Classes Used**:
  - `LeadSearchSidebar` (PascalCase)
  - `FilterListContainer`
  - `FilterList`
  - `FilterListItem`
  - `startToEndLabel`
- **Should Be**:
  - `search-sidebar` (block)
  - `search-sidebar__filter-container`
  - `search-sidebar__filter-list`
  - `search-sidebar__filter-item`

### 4. Main Stylesheet Imports

#### designv2.scss → v2/main.scss
The main stylesheet imports many files, but most are archived/commented out. Active imports include:
- `components/buttons` - Likely BEM compliant based on naming
- `components/cards` - Likely BEM compliant
- `components/forms` - Likely BEM compliant
- `components/navigation` - Likely BEM compliant
- `pages/leads/index` - Should contain lead-specific styles

## Summary of Issues

### 1. **Inconsistent Naming Conventions**
- React components use PascalCase (e.g., `LeadSearch`)
- Some attempts at BEM in layout (e.g., `header__appname`)
- Mixing of camelCase (e.g., `filterHeader`) and snake_case (e.g., `lead_name`)

### 2. **Bootstrap Dependency**
- Heavy use of Bootstrap 3 classes (`glyphicon`, `btn`, etc.)
- No BEM wrappers around Bootstrap components

### 3. **ID vs Class Usage**
- Layout uses IDs for major sections instead of BEM blocks
- React components properly use classes but not BEM format

### 4. **Duplicate/Conflicting Styles**
- `LeadSearchFilter.scss` imported twice with different implementations
- One in containers folder, one in components folder

### 5. **Dynamic Class Generation**
- Classes like `priority-${priority}` and `state-${state}` don't follow BEM
- Should be `lead-card--priority-urgent`, `lead-card--state-open`, etc.

## Recommendations

1. **Establish Clear BEM Blocks**:
   - `lead-search` (main container)
   - `lead-filter` (filter section)
   - `lead-card` (individual lead cards)
   - `search-sidebar` (sidebar filters)

2. **Refactor React Component Classes**:
   - Convert PascalCase to kebab-case
   - Apply proper BEM element and modifier syntax

3. **Create BEM Wrappers for Bootstrap**:
   - Instead of `glyphicon glyphicon-home`, use `lead-card__icon lead-card__icon--home`

4. **Consolidate Duplicate Styles**:
   - Remove duplicate `LeadSearchFilter.scss` files
   - Create single source of truth for each component

5. **Update Dynamic Classes**:
   - Use BEM modifiers for states and priorities
   - Consider data attributes for JavaScript hooks

## Files Requiring Major BEM Refactoring

1. All React component SCSS files in `/app/javascript/lead_search/`
2. Layout file (`application_v2.html.erb`)
3. Any shared components used by the lead search page

## Example BEM Refactoring

### Current (LeadSearchLead.scss):
```scss
.LeadSearchLead {
  .priority { ... }
  .lead_name { ... }
}
```

### Refactored:
```scss
.lead-card {
  &__priority-section { ... }
  &__name { ... }
  
  &--priority-urgent { ... }
  &--state-open { ... }
}
```