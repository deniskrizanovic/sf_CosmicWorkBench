# Generic Software Model — sf_CosmicWorkBench

A COSMIC Generic Software Model of the CosmicWorkBench Salesforce app itself
(the tool turned on its own implementation).

> **Standard:** COSMIC Measurement Manual v5.0 — Part 1 (Principles, Definitions & Rules),
> primarily §4 Mapping Phase (RULE 10–20).
> **Companion files:** [data-groups.md](./data-groups.md) + one file per functional process.

---

## Measurement strategy

| Aspect | Decision |
|--------|----------|
| **Purpose** | Size the functional user requirements delivered by the CosmicWorkBench app |
| **Scope** | The Salesforce app only — Flows, Apex, LWC, triggers, reports, dashboard. Python / SFDMU / diff shell scripts **excluded** (separate tooling layer). |
| **Boundary** | Between the functional users and the app; the Salesforce platform DB is **persistent storage** across the boundary. |
| **Functional users** | (1) **Analyst** — human who drives the UI. (2) **External JSON source** — software actor supplying the bulk-import payload (see [FP08](./08-import-data-movements-from-json.md)). |
| **Layer** | Single application layer. |
| **Objects of interest / data groups** | The app's four custom objects — see [data-groups.md](./data-groups.md). |
| **CFP convention** | 1 CFP per data movement; strict RULE 14/15 dedup (one movement per type+data-group within a process). |

### Modelling rules applied

- **RULE 10 gate.** A functional process must be initiated by an Entry from a functional
  user detecting a triggering event, with ≥2 movements (Entry + Exit or Write).
- **Implementation mechanics fold in, don't stand alone.** Artifacts with no independent
  triggering event — the `cfp_DataMovementOrderSetter` trigger, the
  `cfp_DataGroup_ExternalId_BeforeSave` flow, the `cfp_addDefaultDMsToFuncProcess` seeding
  flow — are folded into their enclosing actor-triggered process. Their *unique* data
  movements are counted there; duplicates collapse per RULE 14/15.
- **Excluded as dev tooling:** `cfp_DataGroupExternalIdBackfill` (manual backfill utility),
  `cfp_getDataMovementsFromMetadata` (commented-out stub), and all non-org scripts.
- **§4.3 Note 4:** implementation-derived data (external-id key, order sequence) is not an
  object of interest.

---

## Functional process register

### Custom-built processes

| ID | Process | CFP | File |
|----|---------|-----|------|
| FP01 | Create Functional Process (incl. seeding + order trigger) | 6 | [01](./01-create-functional-process.md) |
| FP02 | Create Read+Display Pair | 5 | [02](./02-create-read-display-pair.md) |
| FP03 | Copy Functional Process | 8 | [03](./03-copy-functional-process.md) |
| FP04 | Copy Data Movements from Process | 6 | [04](./04-copy-data-movements-from-process.md) |
| FP05 | Create CRUDL with Related Lists | 6 | [05](./05-create-crudl-with-related-lists.md) |
| FP06 | Replicate FP to Context | 7 | [06](./06-replicate-fp-to-context.md) |
| FP07 | Add Email Notification Movements | 3 | [07](./07-add-email-notification.md) |
| FP08 | Import Data Movements from JSON | 5 | [08](./08-import-data-movements-from-json.md) |
| FP09 | Visualise Functional Process | 3 | [09](./09-visualise-functional-process.md) |
| FP10 | Edit Data Movements Inline *(no persistence)* | 2 | [10](./10-edit-data-movements-inline.md) |
| | **Subtotal** | **51** | |

### Reporting processes

| ID | Process | CFP | File |
|----|---------|-----|------|
| FP11 | Report: Detailed FP with DM | 4 | [11](./11-report-detailed-fp-with-dm.md) |
| FP12 | Report: Functional Processes Size | 4 | [12](./12-report-functional-processes-size.md) |
| FP13 | Report: FP Size by Subsystem | 4 | [13](./13-report-fp-size-by-subsystem.md) |
| FP14 | Report: Implementation Types | 4 | [14](./14-report-implementation-types.md) |
| FP15 | Report: Implementation Category | 4 | [15](./15-report-implementation-category.md) |
| FP16 | View Cosmic Dashboard | 4 | [16](./16-view-cosmic-dashboard.md) |
| | **Subtotal** | **24** | |

### OOTB CRUD processes

Grouped one file per object (5 processes each) to avoid 20 near-identical stubs; every
process is individually sized in its file.

| ID | Object | Processes | CFP | File |
|----|--------|-----------|-----|------|
| FP17 | System Context | Create/View/Edit/Delete/List | 16 | [17](./17-ootb-crud-system-context.md) |
| FP18 | Functional Process | View/Edit/Delete/List (Create = FP01) | 13 | [18](./18-ootb-crud-functional-process.md) |
| FP19 | Data Movement | Create/View/Edit/Delete/List | 17 | [19](./19-ootb-crud-data-movement.md) |
| FP20 | Data Group | Create/View/Edit/Delete/List | 16 | [20](./20-ootb-crud-data-group.md) |
| | **Subtotal** | | **62** | |

---

## Total functional size

| Group | Processes | CFP |
|-------|-----------|-----|
| Custom-built | 10 | 51 |
| Reporting | 6 | 24 |
| OOTB CRUD | 19 | 62 |
| **Total** | **35** | **137 CFP** |

---

## Open items / assumptions to confirm

1. **FP01 seeding fold-in** — the `cfp_addDefaultDMsToFuncProcess` flow is treated as part
   of Create Functional Process (record-triggered, no independent event). Object if this
   should be a standalone process.
2. **FP07 Exit** — counted a completion Exit (3 CFP); drop to 2 CFP if the wrapper flow
   shows no user-visible confirmation in the running org.
3. **FP10 no persistence** — sized as-shipped (Entry+Exit, 2 CFP). Rises if inline-save
   persistence is added.
4. **OOTB List views** — counted one List process per object; if list views aren't part of
   the FUR being sized, remove 4 processes (−12 CFP).
5. **Report Reads** — each report counts 2 Reads (FP + DM) from its join. If a report's
   grouping doesn't actually traverse both objects at runtime, adjust to 1 Read (−1 CFP each).
