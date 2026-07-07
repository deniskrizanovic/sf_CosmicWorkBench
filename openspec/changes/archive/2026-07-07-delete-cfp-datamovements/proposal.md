## Why

The `cfp_DataMovements` Lightning Web Component is a standalone data-entry prototype that operates entirely on in-memory mock data — it performs no persistence, calls no Apex, and is not placed on any Lightning page (FlexiPage). It is dead code that adds maintenance and audit surface without delivering functionality.

## What Changes

- Remove the `cfp_DataMovements` LWC bundle (`cfp_DataMovements.js`, `cfp_DataMovements.html`, `cfp_DataMovements.js-meta.xml`).
- Remove the `cfp_DataMovements` `LightningComponentBundle` member from `src/package.xml`.
- **Out of scope (retained):** the name-adjacent but functionally separate `cfp_DataMovementsImporter` / `cfp_DataMovementsImporterTest` / `cfp_DataMovementsOrderingTest` Apex classes and the `cfp_DataMovementsJSONImporter` flow. The flow remains referenced by the `System_Context_Record_Page` and `cfp_SystemContext_Dynamic` FlexiPages and is unaffected.

## Capabilities

### New Capabilities
<!-- None. This is a removal-only change. -->

### Modified Capabilities
<!-- None. No spec-level behavior changes; the component has no documented capability spec. -->

## Impact

- **Removed source:** `src/main/default/lwc/cfp_DataMovements/` (3 files) and one member entry in `src/package.xml`.
- **References:** No FlexiPage, Apex class, or flow references the LWC bundle `cfp_DataMovements`; removal is non-breaking.
- **Org deployment:** After local removal, the component must be deleted from the target org via a destructive deploy (`destructiveChanges.xml`) — a standard delete does not remove org components.
- **Verification:** ESLint / Jest have no tests for this bundle; `npm run lint` and `npm run test:unit` should remain green.
