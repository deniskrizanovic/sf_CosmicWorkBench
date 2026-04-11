---
name: add-traversal-warnings-mapping
overview: Add mapping for `traversalWarnings` from import JSON to the Screen Flow response.
todos:
  - id: update-apex-classes-fields
    content: Add traversalWarnings to Response and PayloadRoot in cfp_DataMovementsImporter.cls
    status: pending
  - id: update-apex-logic
    content: Update parsePayload and importFromJson to handle traversalWarnings
    status: pending
  - id: update-flow-metadata
    content: Update Screen Flow to display traversal warnings on the Finished screen
    status: pending
  - id: update-tests
    content: Add test coverage for traversalWarnings in cfp_DataMovementsImporterTest.cls
    status: pending
isProject: false
---

1.  **Modify [cfp_DataMovementsImporter.cls](src/main/default/classes/cfp_DataMovementsImporter.cls)**:
    - Update `Response` class to include `List<String> traversalWarnings`.
    - Update `PayloadRoot` private class to include `List<String> traversalWarnings`.
    - Update `parsePayload` method to extract `traversalWarnings` from the JSON root.
    - Update `importFromJson` method to populate `res.traversalWarnings` from `payload.traversalWarnings`.
2.  **Update [cfp_DataMovementsJSONImporter.flow-meta.xml](src/main/default/flows/cfp_DataMovementsJSONImporter.flow-meta.xml)**:
    - Modify the `Finished` screen.
    - Add a new `DisplayText` field or update `FinishedText` to display the traversal warnings.
    - Since Flow can't easily iterate and display a list of strings in a single `DisplayText` component without a loop, I will also add a `traversalWarningsString` to the Apex `Response` which is a joined version of the list for easy display.
3.  **Update [cfp_DataMovementsImporterTest.cls](src/main/default/classes/cfp_DataMovementsImporterTest.cls)**:
    - Add a test case to verify `traversalWarnings` are correctly parsed and returned in the response.
