---
name: Plan Invocable JSON Mapper
overview: Design and implement an invocable Apex action that accepts large JSON from Flow, parses data movements, and inserts `cfp_Data_Movements__c` records with an optional replace mode while taking Functional Process Id from a separate Flow input.
todos:
  - id: create-invocable-contract
    content: Define invocable request/response wrappers and method signature for Flow
    status: pending
  - id: implement-json-mapper
    content: Implement JSON DTO parsing, field mapping, and insert/replace DML behavior controlled by flag
    status: pending
  - id: add-validation-errors
    content: Add robust input validation and structured error handling for Flow consumption
    status: pending
  - id: write-apex-tests
    content: Create unit tests for insert mode, replace mode, parse failures, and input validation
    status: pending
  - id: document-flow-usage
    content: Document expected Flow inputs/outputs and v1 mapping limitations
    status: pending
isProject: false
---

# Invocable Apex JSON-to-DataMovements Plan

## Goal

Build a Flow-invocable Apex action that receives a JSON string like [data/JSONImports/WorkOrder.json](/Users/dkrizanovic/My Drive/salesforce/sf_CosmicWorkBench/data/JSONImports/WorkOrder.json), parses `dataMovements[]`, and inserts `cfp_Data_Movements__c` rows linked to a Flow-supplied Functional Process Id, with an optional replace-existing mode.

## Scope (Confirmed)

- Input source for functional process: separate Flow input (not JSON `functionalProcessId`).
- Persistence behavior: insert-only by default, with optional replace-existing mode.
- Mapping for v1:
  - Map core fields from JSON.
  - Leave non-core custom fields null/default.
  - Add clear extension points for future mapping rules.

## Target Metadata

- Object: [src/main/default/objects/cfp_Data_Movements__c/cfp_Data_Movements__c.object-meta.xml](/Users/dkrizanovic/My Drive/salesforce/sf_CosmicWorkBench/src/main/default/objects/cfp_Data_Movements__c/cfp_Data_Movements__c.object-meta.xml)
- Important fields for v1:
  - `Name` (Step Name)
  - `cfp_order__c`
  - `cfp_movementtype__c`
  - `cfp_implementationtype__c`
  - `cfp_is_API_Call__c`
  - `cfp_FunctionalProcess__c`

## Implementation Design

- Create a new invocable class named `cfp_DataMovementsImporter` with:
  - `@InvocableMethod` accepting a list of request wrappers.
  - Request fields:
    - `functionalProcessId` (Id/String from Flow)
    - `jsonPayload` (Long Text from Flow)
    - `replaceExistingForProcess` (Boolean, optional, default `false`)
  - Response fields per request:
    - `success`
    - `insertedCount`
    - `errorMessage`
- Parse JSON using typed Apex DTOs:
  - Root DTO with `dataMovements` list.
  - Movement DTO with `name`, `order`, `movementType`, `implementationType`, `isApiCall`, `dataGroupRef`.
- DML behavior:
  - If `replaceExistingForProcess = false`: insert all parsed rows.
  - If `replaceExistingForProcess = true`: delete existing `cfp_Data_Movements__c` where `cfp_FunctionalProcess__c = functionalProcessId`, then insert parsed rows.
- Map fields:
  - `Name <- name`
  - `cfp_order__c <- order`
  - `cfp_movementtype__c <- movementType`
  - `cfp_implementationtype__c <- normalized implementationType` (case-normalize to existing picklist values where needed)
  - `cfp_is_API_Call__c <- isApiCall`
  - `cfp_FunctionalProcess__c <- functionalProcessId (Flow input)`
  - `cfp_Data_Group_Name__c <- dataGroupRef` (store raw ref as optional helpful carry-forward for later lookup mapping)
- Error handling:
  - Validate required inputs before parse.
  - Catch parse/DML errors and return structured response for Flow fault handling.
  - Keep method bulk-safe for multiple Flow requests.

## Test Strategy

- Add Apex tests covering:
  - Valid payload inserts new rows.
  - Second run with same payload inserts additional rows (duplicates allowed by design).
  - Replace mode deletes prior rows for that process and inserts new set.
  - Invalid JSON returns graceful error.
  - Missing functionalProcessId / empty payload validation paths.
  - Picklist normalization behavior for `implementationType`.
- Assert counts and key mapped field values.

## Flow Usage Contract

- Flow passes:
  - `functionalProcessId` (record Id variable)
  - `jsonPayload` (pasted JSON string)
  - `replaceExistingForProcess` (optional Boolean; default `false`)
- Flow receives response for logging/screen display and optional fault branch.

## Notes for Future Iterations

- Add optional `dataGroupRef -> cfp_DataGroups__c` lookup resolution when mapping rules are confirmed.
- Expand mapping to additional custom fields when explicit source rules are provided.

