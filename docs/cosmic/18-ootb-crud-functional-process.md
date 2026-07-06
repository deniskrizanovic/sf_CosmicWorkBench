# FP18 — OOTB CRUD: Functional Process

> [GSM index](./GSM-overview.md) · [Data groups](./data-groups.md)
> COSMIC v5.0 Part 1 §4 (RULE 10, 13–20)

Standard Salesforce record-page processes for `cfp_FunctionalProcess__c` (DG2).
Implementation category = **OOTB**. Object of interest = Functional Process.

| # | Process | Trigger | Data movements | CFP |
|---|---------|---------|----------------|-----|
| 18a | Create Functional Process | — | **See [FP01](./01-create-functional-process.md)** — the custom seeding flow + trigger make this a richer process than plain OOTB create. Not double-counted here. | *(FP01)* |
| 18b | View Functional Process | Analyst opens the record | E (request) + R (Functional Process) + X (display) | **3** |
| 18c | Edit Functional Process | Analyst saves an edit | E (attributes) + R (Functional Process) + W (Functional Process) + X (confirm) | **4** |
| 18d | Delete Functional Process | Analyst deletes the record | E (request) + W (delete, RULE 20) + X (confirm) | **3** |
| 18e | List Functional Processes | Analyst opens a list view | E (request) + R (Functional Process) + X (list) | **3** |

**Subtotal: 13 CFP** (4 processes counted here; Create = FP01).

> 18b "View" covers the generic record page. The bespoke SVG rendering on that page is a
> separate process — see [FP09 Visualise Functional Process](./09-visualise-functional-process.md).
