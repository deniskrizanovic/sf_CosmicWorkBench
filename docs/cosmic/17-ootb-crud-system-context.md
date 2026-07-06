# FP17 — OOTB CRUD: System Context

> [GSM index](./GSM-overview.md) · [Data groups](./data-groups.md)
> COSMIC v5.0 Part 1 §4 (RULE 10, 13–20)

Standard Salesforce record-page processes for `cfp_System_Context__c` (DG1). Each is a
distinct functional process with its own triggering event (RULE 10). Implementation
category = **OOTB** (platform-delivered). Object of interest = System Context.

| # | Process | Trigger | Data movements | CFP |
|---|---------|---------|----------------|-----|
| 17a | Create System Context | Analyst saves a System Context | E (attributes) + W (System Context) + X (confirm) | **3** |
| 17b | View System Context | Analyst opens the record | E (request) + R (System Context) + X (display) | **3** |
| 17c | Edit System Context | Analyst saves an edit | E (attributes) + R (System Context) + W (System Context) + X (confirm) | **4** |
| 17d | Delete System Context | Analyst deletes the record | E (request) + W (delete, RULE 20) + X (confirm) | **3** |
| 17e | List System Contexts | Analyst opens a list view | E (request) + R (System Context) + X (list) | **3** |

**Subtotal: 16 CFP** (5 processes).

> Deletes count as a single Write (RULE 20). Each process moves only the System Context data
> group; related-object cascade is not part of the FUR here.
