## REMOVED Requirements

### Requirement: Data movements entry table
The `cfp_DataMovements` Lightning Web Component SHALL be removed. It provided an in-memory, non-persisted editable table for entering data-movement rows (name, movement type, data group, implementation type, comments) with add-row, inline-edit, row reorder, and client-side validation.

**Reason**: The component is a standalone prototype operating solely on mock data — it persists nothing, calls no Apex, and is not placed on any FlexiPage. It is dead code with no runtime consumers.

**Migration**: None required. No page, Apex class, or flow references the LWC bundle `cfp_DataMovements`. The functionally separate `cfp_DataMovementsImporter` Apex and `cfp_DataMovementsJSONImporter` flow (used for actual data import) are unaffected and remain in place.

#### Scenario: Component no longer available for page placement
- **WHEN** an admin edits a Lightning page in App Builder after this change is deployed
- **THEN** `cfp Data Movements` is not offered as a placeable custom component

#### Scenario: Removal is non-breaking
- **WHEN** the change is deployed to the org
- **THEN** no FlexiPage, Apex class, or flow fails to deploy or resolve due to a missing `cfp_DataMovements` component
