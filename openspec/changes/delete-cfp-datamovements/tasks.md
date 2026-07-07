## 1. Preconditions

- [x] 1.1 Create a feature branch (never edit on `main`), e.g. `chore/delete-cfp-datamovements`
- [x] 1.2 Re-confirm no references to the LWC bundle: `grep -rn "cfp_DataMovements<" src/main/default/flexipages/` and confirm results are only the `cfp_DataMovementsJSONImporter` flow (out of scope)

## 2. Remove Local Source

- [x] 2.1 Delete the bundle directory `src/main/default/lwc/cfp_DataMovements/` (`.js`, `.html`, `.js-meta.xml`)
- [x] 2.2 Remove the `<members>cfp_DataMovements</members>` `LightningComponentBundle` entry from `src/package.xml`

## 3. Verify Local

- [x] 3.1 Run `npm run lint` — confirm green
- [x] 3.2 Run `npm run test:unit` — confirm green
- [x] 3.3 Confirm `cfp_DataMovementsImporter*`, `cfp_DataMovementsOrderingTest`, and `cfp_DataMovementsJSONImporter` flow are still present and untouched

## 4. Org Removal (on explicit user confirmation only)

- [x] 4.1 Author a `destructiveChanges.xml` with type `LightningComponentBundle`, member `cfp_DataMovements`
- [x] 4.2 Deploy the destructive change to the target org
- [x] 4.3 Verify the component no longer appears in the org (App Builder component list / metadata retrieve)

## 5. Sync GSM Docs (`docs/cosmic/`)

FP10 in the Generic Software Model is sourced solely from the `cfp_DataMovements` LWC; removing the component removes the process.

- [x] 5.1 Delete `docs/cosmic/10-edit-data-movements-inline.md` (FUR source is the removed LWC)
- [x] 5.2 In `docs/cosmic/GSM-overview.md`, remove the FP10 register row
- [x] 5.3 Update Custom-built subtotal `51 → 49` CFP (register table + total table row: `10 | 51` → `9 | 49`)
- [x] 5.4 Update grand total `35 → 34` processes and `137 → 135` CFP
- [x] 5.5 Remove open item #3 ("FP10 no persistence") and renumber items #4→#3, #5→#4
- [x] 5.6 Leave FP11–FP20 IDs and the out-of-scope import refs (`cfp_DataMovementsJSONImporter`, `cfp_DataMovementsImporter`, `cfp_getDataMovements`) untouched

## 6. Wrap Up

- [ ] 6.1 Commit with conventional message (e.g. `chore(lwc): delete unused cfp_DataMovements component`)
- [ ] 6.2 Push branch, merge to main, delete branch per git workflow
