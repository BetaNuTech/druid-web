# BEM Fixes Needed for leads/show.html.erb

## Summary of Non-BEM Classes in Main File

### 1. Bootstrap Classes to Replace
- `container-fluid` (lines 82, 97, 129, 136)
- `row` (lines 137, 330, 380, 390, 420)
- `col-md-4` (lines 139, 204, 282)
- `col-md-12` (lines 331, 381, 391, 421)
- `alert alert--danger` (line 83) - Mixed Bootstrap/BEM

### 2. Section Classes Not Following BEM
- `state-controls-section` (line 78) - Inconsistent with other sections
- `quick-nav-section` (line 96) - Could be more specific block
- `section-wrapper` (lines 130, 393, 398, 403, 408, 413) - Too generic
- `lead-content` (line 136) - Should be `lead-detail__content`
- `lead-errors` (line 83) - Should be `lead-detail__errors`

### 3. Quick Navigation Classes
- `quick-nav-links` (line 101) → Should be `quick-nav-section__links`
- `quick-nav-link` (lines 102, 107, 112, 116, 120) → Should be `quick-nav-section__link`
- `quick-nav-duplicates` (line 107) → Should be `quick-nav-section__link--duplicates`

### 4. Card Component Classes
- `info-card` (lines 141, 206, 284, 332, 382) → Keep as block
- `contact-card` (line 141) → Should be `info-card--contact`
- `property-card` (line 206) → Should be `info-card--property`
- `preferences-card` (line 284) → Should be `info-card--preferences`
- `notes-card` (line 332) → Should be `info-card--notes`
- `source-doc-card` (line 382) → Should be `info-card--source-doc`
- `card-header` (lines 142, 207, 285, 333) → Should be `info-card__header`
- `card-body` (lines 145, 210, 288, 336) → Should be `info-card__body`

### 5. Contact Information Classes
- `contact-item` (lines 147, 161, 174, 190) → Should be `info-card__item`
- `contact-icon` (lines 148, 162, 175, 191) → Should be `info-card__icon`
- `contact-content` (lines 149, 163, 176, 192) → Should be `info-card__content`
- `contact-label` (lines 150, 164, 177, 193) → Should be `info-card__label`
- `contact-value` (lines 151, 165, 179, 185, 195) → Should be `info-card__value`
- `missing-email` (line 174) → Should be `info-card__item--missing-email`
- `missing` (line 185) → Should be `info-card__value--missing`

### 6. Property Information Classes
- `property-item` (lines 212, 220, 231, 245, 257) → Should be `info-card__item`
- `property-icon` (lines 213, 222, 232, 247, 258) → Should be `info-card__icon`
- `property-content` (lines 214, 223, 233, 248, 259) → Should be `info-card__content`
- `property-label` (lines 215, 224, 234, 249, 260) → Should be `info-card__label`
- `property-value` (lines 216, 226, 235, 251, 261) → Should be `info-card__value`
- `duplicate-warning` (line 265) → Should be `info-card__warning`

### 7. Preferences Classes
- `preference-item` (lines 289, 297, 307, 317) → Should be `info-card__item`
- `pref-icon` (lines 290, 298, 308, 318) → Should be `info-card__icon`
- `pref-content` (lines 291, 299, 309, 319) → Should be `info-card__content`
- `pref-label` (lines 292, 300, 310, 320) → Should be `info-card__label`
- `pref-value` (lines 293, 301, 311, 321) → Should be `info-card__value`

### 8. Notes Classes
- `note-item` (lines 338, 348, 358) → Should be `info-card__item`
- `follow-up-note` (line 338) → Should be `info-card__item--follow-up`
- `lead-notes-item` (line 348) → Should be `info-card__item--lead-notes`
- `import-notes-item` (line 358) → Should be `info-card__item--import-notes`
- `note-header` (lines 349, 359) → Should be `info-card__header`
- `note-icon` (lines 339, 350, 360) → Should be `info-card__icon`
- `note-content` (line 340) → Should be `info-card__content`
- `note-label` (lines 341, 351, 361) → Should be `info-card__label`
- `note-value` (line 342) → Should be `info-card__value`
- `note-text` (lines 353, 363) → Should be `info-card__text`

### 9. Empty State Classes
- `empty-state` (lines 238, 368) → Should be component block
- `empty-icon` (lines 239, 369) → Should be `empty-state__icon`

## Recommended Approach

1. **Create a unified card component** that can handle all the different card types with modifiers
2. **Replace Bootstrap grid classes** with custom BEM grid classes or keep them as utility classes
3. **Standardize section wrappers** to use consistent naming
4. **Use proper BEM modifiers** instead of additional classes (e.g., `--missing` instead of separate `missing` class)

## Priority Fixes

1. **High Priority**: Fix the inconsistent card component classes - they're used throughout and need consistency
2. **Medium Priority**: Fix section classes and quick navigation
3. **Low Priority**: Bootstrap grid classes (may want to keep for compatibility)

## Suggested BEM Structure

```
.lead-detail
  .lead-detail__errors
  .lead-detail__state-controls
  .lead-detail__quick-nav
    .lead-detail__quick-nav-links
    .lead-detail__quick-nav-link
    .lead-detail__quick-nav-link--duplicates
  .lead-detail__content
    .info-card
      .info-card--contact
      .info-card--property
      .info-card--preferences
      .info-card--notes
      .info-card__header
      .info-card__body
      .info-card__item
      .info-card__item--missing-email
      .info-card__icon
      .info-card__content
      .info-card__label
      .info-card__value
      .info-card__value--missing
      .info-card__text
      .info-card__warning
    .empty-state
      .empty-state__icon
      .empty-state__text
```