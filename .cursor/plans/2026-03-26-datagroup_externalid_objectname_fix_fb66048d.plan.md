---
name: DataGroup ExternalId ObjectName Fix
overview: Change the DataGroup external ID formula from `systemContext|dataGroupName` to `systemContext|objectName`, updating the util class, the before-save flow, and adding targeted tests that prove the two fields can differ.
todos:
  - id: fix-util
    content: "Update cfp_DataGroupExternalIdUtil.cls: rename param to objectName, use dg.cfp_Object_Name__c in buildExternalIdFromDataGroup"
    status: pending
  - id: fix-flow
    content: Update flow formula to use {!$Record.cfp_Object_Name__c} and add blank guard
    status: pending
  - id: fix-flow-tests
    content: Add test to cfp_DataGroupsExternalIdFlowTest where Name ≠ cfp_Object_Name__c
    status: pending
  - id: fix-backfill-tests
    content: Add test to cfp_DataGroupExternalIdBackfillTest where Name ≠ cfp_Object_Name__c
    status: pending
isProject: false
---

# DataGroup External ID: Switch from Name to Object Name

## Problem

The external ID is currently built from `cfp_DataGroups__c.Name`. It should use `cfp_DataGroups__c.cfp_Object_Name__c` so that two Data Groups for different objects in the same System Context cannot share an ID, and the canonical key stays stable even if the record Name is renamed.

## Current formula (two places)

**Util class** — `[cfp_DataGroupExternalIdUtil.cls](src/main/default/classes/cfp_DataGroupExternalIdUtil.cls)`:

```apex
// Line 15 — uses dg.Name (wrong)
return buildExternalId(String.valueOf(dg.cfp_System_Context__c), dg.Name);
```

**Before-save flow** — `[cfp_DataGroup_ExternalId_BeforeSave.flow-meta.xml](src/main/default/flows/cfp_DataGroup_ExternalId_BeforeSave.flow-meta.xml)`:

```xml
<!-- Line 22 — uses {!$Record.Name} (wrong) -->
<expression>IF(ISBLANK(...), "", LOWER({!$Record.cfp_System_Context__c}) & "|" & LOWER(TRIM({!$Record.Name})))</expression>
```

## Changes required

### 1. `cfp_DataGroupExternalIdUtil.cls`

- Rename method parameter `dataGroupName` → `objectName` for clarity.
- In `buildExternalIdFromDataGroup`, pass `dg.cfp_Object_Name__c` instead of `dg.Name`.

### 2. `cfp_DataGroup_ExternalId_BeforeSave.flow-meta.xml`

- Replace `{!$Record.Name}` with `{!$Record.cfp_Object_Name__c}` in the `canonicalExternalId` formula.
- Also guard against a blank `cfp_Object_Name__c` (add `ISBLANK({!$Record.cfp_Object_Name__c})` to the `OR` condition).

### 3. `cfp_DataGroupsExternalIdFlowTest.cls`

- Existing tests use `Name = 'WorkOrder'` and `cfp_Object_Name__c = 'WorkOrder'` (equal), so assertions remain valid.
- Add one new test where `Name` differs from `cfp_Object_Name__c` to prove the flow keys on `cfp_Object_Name__c`.

### 4. `cfp_DataGroupExternalIdBackfillTest.cls`

- Existing tests remain valid for the same reason.
- Add one new test where `Name ≠ cfp_Object_Name__c` to prove the backfill uses `cfp_Object_Name__c`.

### No changes needed

- `cfp_DataGroupExternalIdBackfill.cls` — calls `buildExternalIdFromDataGroup`, picks up the fix automatically.
- `cfp_DataMovementsImporter.cls` — uses `buildExternalIdFromDataGroupRef(systemContextToken, dataGroupRef)` where `dataGroupRef` is already the API object name from the JSON payload.
- `cfp_DataMovementsImporterTest.cls` — test data already uses `cfp_Object_Name__c = 'WorkOrder'` matching the JSON ref; no change needed.

## Impact on existing data

Any `cfp_DataGroups__c` records where `Name ≠ cfp_Object_Name__c` will have a stale `cfp_External_Id__c` after the flow change. The existing backfill class (`cfp_DataGroupExternalIdBackfill.runBackfill(true)`) handles this — run it after deployment.