---
name: Add artifactName field mapping to cfp_DataMovementsImporter.cls
overview: Map the new `artifactName` field from JSON payload to the `cfp_artifactName__c` field on `cfp_Data_Movements__c` records and update tests.
todos:
  - id: update-build-rows-mapping
    content: Modify `buildRows` method in `cfp_DataMovementsImporter.cls` to map `artifactName`.
    status: pending
  - id: update-debug-log-with-artifact-name
    content: Update `debugLog` in `buildRows` to include `artifactName`.
    status: pending
  - id: update-test-payload
    content: Update `buildPayload` in `cfp_DataMovementsImporterTest.cls` to include `artifactName`.
    status: pending
  - id: update-test-assertions
    content: Update `testInsertModeCreatesRows` in `cfp_DataMovementsImporterTest.cls` to assert `artifactName` mapping.
    status: pending
isProject: false
---

# Plan - Add `artifactName` Field Mapping

### Summary
Map `artifactName` from JSON payload to `cfp_artifactName__c` in `cfp_DataMovementsImporter.cls` and update `cfp_DataMovementsImporterTest.cls`.

### Changes

#### [src/main/default/classes/cfp_DataMovementsImporter.cls](src/main/default/classes/cfp_DataMovementsImporter.cls)
- Update `buildRows` to map `artifactName` from JSON.
- Update `debugLog` in `buildRows` to include `artifactName`.

```apex
// ...
row.cfp_movementtype__c = asString(movement.get('movementType'));
row.cfp_artifactName__c = asString(movement.get('artifactName')); // New mapping
// ...
debugLog(
    'H3',
    'cfp_DataMovementsImporter.buildRows',
    'Data movement dataGroupRef resolution decision',
    new Map<String, Object>{
        'movementName' => row.Name,
        'artifactName' => row.cfp_artifactName__c, // Added to log
        'dataGroupRef' => dataGroupRef,
// ...
```

#### [src/main/default/classes/cfp_DataMovementsImporterTest.cls](src/main/default/classes/cfp_DataMovementsImporterTest.cls)
- Update `buildPayload` to include `artifactName` in JSON.
- Update `testInsertModeCreatesRows` to assert `cfp_artifactName__c` is correctly mapped.

```apex
// ...
private static String buildPayload() {
    return '{"dataMovements":[' +
        '{"name":"Open record page (WorkOrder)","order":1,"movementType":"E","dataGroupRef":"WorkOrder","implementationType":"flexipage","isApiCall":false,"artifactName":"WO_Record_Page"},' +
// ...
List<cfp_Data_Movements__c> rows = [
    SELECT Name, cfp_order__c, cfp_movementtype__c, cfp_implementationtype__c, cfp_is_API_Call__c, cfp_FunctionalProcess__c, cfp_artifactName__c
// ...
System.assertEquals('WO_Record_Page', rows[0].cfp_artifactName__c);
```
