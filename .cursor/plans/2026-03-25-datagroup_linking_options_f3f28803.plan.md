---
name: DataGroup Linking Options
overview: Implement Option 2 by making `cfp_External_Id__c` the deterministic join key for Data Group resolution, including remediation/backfill of existing Data Groups and flow automation to keep external ids populated on create/update.
todos:
  - id: finalize-external-id-contract
    content: Finalize and document external-id format and normalization rules for `dataGroupRef` -> `cfp_External_Id__c`.
    status: pending
  - id: remediate-existing-datagroups
    content: Backfill and deduplicate existing `cfp_DataGroups__c` external ids, including conflict handling and reporting.
    status: pending
  - id: build-datagroup-before-save-flow
    content: Create a before-save record-triggered flow on Data Group to populate/recompute `cfp_External_Id__c` on create and relevant edits.
    status: pending
  - id: update-importer-to-external-id
    content: Update importer to resolve Data Groups by external id and assign `cfp_DataGroups__c` in bulk-safe fashion, using non-blocking handling for unresolved references.
    status: pending
  - id: expand-tests-validation
    content: Add Apex and flow validation coverage for remediated data, external-id resolution, and unresolved-reference behavior.
    status: pending
isProject: true
---

# Option 2 Execution Plan: External ID Linking

Current importer parses `dataGroupRef` from JSON payloads but does not assign `cfp_Data_Movements__c.cfp_DataGroups__c`. This plan commits to Option 2 and treats `cfp_DataGroups__c.cfp_External_Id__c` as the single deterministic key for Data Movement linking.

## Current state observed

- Importer sets movement fields but never sets `cfp_DataGroups__c` in `[src/main/default/classes/cfp_DataMovementsImporter.cls](/Users/dkrizanovic/My Drive/salesforce/sf_CosmicWorkBench/src/main/default/classes/cfp_DataMovementsImporter.cls)`.
- Payloads and tests already contain `dataGroupRef` (example values: `WorkOrder`, `Warranty__c`, `status/errors/etc`) in `[data/JSONImports/WorkOrder.json](/Users/dkrizanovic/My Drive/salesforce/sf_CosmicWorkBench/data/JSONImports/WorkOrder.json)` and `[src/main/default/classes/cfp_DataMovementsImporterTest.cls](/Users/dkrizanovic/My Drive/salesforce/sf_CosmicWorkBench/src/main/default/classes/cfp_DataMovementsImporterTest.cls)`.
- Data movement has lookup `cfp_DataGroups__c` to `cfp_DataGroups__c` in `[src/main/default/objects/cfp_Data_Movements__c/fields/cfp_DataGroups__c.field-meta.xml](/Users/dkrizanovic/My Drive/salesforce/sf_CosmicWorkBench/src/main/default/objects/cfp_Data_Movements__c/fields/cfp_DataGroups__c.field-meta.xml)`.

## Scope and target behavior

- `cfp_DataMovementsImporter` resolves each movement to Data Group using external id, not name.
- `dataGroupRef` in JSON is transformed into the same canonical key used by Data Group external id.
- Existing Data Groups are remediated so historical rows can be matched by the new key.
- A before-save flow keeps `cfp_External_Id__c` synchronized whenever Data Group records are created or edited.

## External-id contract

- Canonical format: `<objectNameOrContext>|<normalizedDataGroupRef>`.
- Normalization rules:
  - trim whitespace;
  - collapse repeated spaces;
  - lowercase;
  - keep separators (`__c`, `/`, `_`) intact.
- For Data Groups with `cfp_Object_Name__c`, use that as the left segment; otherwise use a default context token (to be fixed during implementation).

## Remediation of existing data

- Inventory existing `cfp_DataGroups__c` records and compute expected external ids.
- Backfill missing/blank `cfp_External_Id__c`.
- Detect collisions where multiple records produce the same external id:
  - produce a collision report,
  - apply deterministic keep/merge rule or manual resolution list before enforcement.
- Validate uniqueness after remediation and re-run conflict check before deployment.

## Before-save flow implementation

- Add record-triggered flow on `cfp_DataGroups__c` (before save, on create and update).
- Entry criteria: run when `Name` or `cfp_Object_Name__c` changes, or external id is blank.
- Flow computes canonical external id using same contract and assigns `cfp_External_Id__c`.
- Add guard logic to avoid unnecessary rewrites and to preserve deterministic output.

## Importer changes

- Extract all `dataGroupRef` values from payload and compute canonical external ids in-memory.
- Query `cfp_DataGroups__c` once by `cfp_External_Id__c IN :keys`.
- Assign `row.cfp_DataGroups__c` from `externalId -> Id` map during row build.
- Response behavior:
  - default non-blocking: unresolved keys listed in response message and movement inserted with blank `cfp_DataGroups__c`;
  - strict mode remains optional for later rollout and is off by default.

## Validation and testing

- Apex tests:
  - imported rows link to expected `cfp_DataGroups__c` via external id;
  - replace mode still preserves valid linkage after reinsert;
  - unresolved dataGroupRef behavior defaults to non-blocking with warning output.
- Flow tests/validation:
  - insert populates external id;
  - update of name/object recomputes external id;
  - unchanged key inputs do not churn field values.
- Remediation validation:
  - pre/post counts for populated external id,
  - zero duplicate external ids before enabling strict uniqueness assumptions.
