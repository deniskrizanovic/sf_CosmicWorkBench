## Context

`cfp_DataMovements` is an LWC bundle at `src/main/default/lwc/cfp_DataMovements/` (`.js`, `.html`, `.js-meta.xml`). The `.js-meta.xml` marks it `isExposed=true` targeting RecordPage/HomePage/AppPage, but a repo-wide search confirms no FlexiPage places the bundle. It is listed as a `LightningComponentBundle` member in `src/package.xml`. The name-adjacent Apex (`cfp_DataMovementsImporter*`, `cfp_DataMovementsOrderingTest`) and flow (`cfp_DataMovementsJSONImporter`) are a separate import subsystem and are explicitly out of scope.

This is a Salesforce DX project. Removing files locally does not remove the component from the connected org; org-side removal requires a destructive deployment.

## Goals / Non-Goals

**Goals:**
- Delete the `cfp_DataMovements` LWC bundle from local source.
- Remove its member entry from `src/package.xml`.
- Remove the component from the target org via a destructive deploy.
- Keep `npm run lint` and `npm run test:unit` green.

**Non-Goals:**
- Touching `cfp_DataMovementsImporter`, `cfp_DataMovementsImporterTest`, `cfp_DataMovementsOrderingTest`, or the `cfp_DataMovementsJSONImporter` flow.
- Modifying any FlexiPage (none reference the LWC bundle).

## Decisions

- **Delete the whole bundle directory, not individual files.** LWC bundles are atomic; removing the directory is the clean unit of removal.
- **Edit `src/package.xml` to drop the member.** Leaving a stale `cfp_DataMovements` member would cause retrieve/deploy manifest mismatches. Alternative — leaving it — rejected as it produces a dangling reference.
- **Use a `destructiveChanges.xml` deploy for org removal** (component type `LightningComponentBundle`, member `cfp_DataMovements`). Alternative — `sf project deploy` of the deletion — does not remove org components; only destructive changes do. Actual org deploy is gated on user confirmation since it is an irreversible, outward-facing operation.

## Risks / Trade-offs

- [Hidden runtime reference not caught by static search] → Grep already covers `.xml`/`.js`/`.html`/`.cls`; the bundle has no Apex/flow consumers. Verify org has no active page usage before destructive deploy.
- [Org destructive deploy is irreversible] → Confirm with user before running; the local git revert restores source but not org state, so treat the deploy as the point of no return.

## Migration Plan

1. Delete `src/main/default/lwc/cfp_DataMovements/`.
2. Remove the `cfp_DataMovements` member from `src/package.xml`.
3. Run `npm run lint` and `npm run test:unit` to confirm green.
4. (Org, on user confirmation) Deploy a `destructiveChanges.xml` removing `LightningComponentBundle:cfp_DataMovements`.
5. Rollback: `git revert` the source deletion; if already deployed, redeploy the bundle from the reverted source.

## Open Questions

- Should org-side destructive deploy run as part of this change, or is local source removal sufficient for now? (Default: local removal here; org destructive deploy only on explicit user go-ahead.)
