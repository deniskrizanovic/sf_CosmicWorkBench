---
name: format-traversal-warnings
overview: Bold headings and use single-line breaks for traversal warnings in Flow.
todos:
  - id: format-warnings-apex-logicLine64-103
    content: Format traversal warnings with bold headings and <br/> in cfp_DataMovementsImporter.cls
    status: pending
  - id: update-tests-formatting
    content: Update test coverage in cfp_DataMovementsImporterTest.cls to verify formatting
    status: pending
isProject: false
---

1. **Update [cfp_DataMovementsImporter.cls](src/main/default/classes/cfp_DataMovementsImporter.cls)**:
    - Modify `importFromJson` loop.
    - Process each warning in `res.traversalWarnings`.
    - Detect heading by finding first `: ` (colon + space).
    - Wrap heading (up to colon) in `<b>` tags.
    - Join processed warnings with `<br/>` for single-line display in Flow.

2. **Update [cfp_DataMovementsImporterTest.cls](src/main/default/classes/cfp_DataMovementsImporterTest.cls)**:
    - Update `buildPayloadWithWarnings` to include colon in warning string.
    - Update `testImporterParsesTraversalWarnings` to verify `<b>` tags and `<br/>` join.