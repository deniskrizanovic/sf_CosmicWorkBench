# FP19 — OOTB CRUD: Data Movement

> [GSM index](./GSM-overview.md) · [Data groups](./data-groups.md)
> COSMIC v5.0 Part 1 §4 (RULE 10, 13–20)

Standard Salesforce record-page processes for `cfp_Data_Movements__c` (DG3).
Implementation category = **OOTB**. Object of interest = Data Movement.

The `cfp_DataMovementOrderSetter` trigger fires on Create and Edit here. Its Write of the
renumbered Data Movement collapses into the same-data-group Write already counted (RULE 14).
Its **Read of sibling Data Movements** is a unique Read within Create/Edit and is folded in
below (per the agreed rule for non-independently-triggered mechanics).

| # | Process | Trigger | Data movements | CFP |
|---|---------|---------|----------------|-----|
| 19a | Create Data Movement | Analyst saves a Data Movement | E (attributes) + R (sibling Data Movements, order trigger) + W (Data Movement) + X (confirm) | **4** |
| 19b | View Data Movement | Analyst opens the record | E (request) + R (Data Movement) + X (display) | **3** |
| 19c | Edit Data Movement | Analyst saves an edit | E (attributes) + R (Data Movement — incl. sibling reorder) + W (Data Movement) + X (confirm) | **4** |
| 19d | Delete Data Movement | Analyst deletes the record | E (request) + W (delete, RULE 20) + X (confirm) | **3** |
| 19e | List Data Movements | Analyst opens a list view | E (request) + R (Data Movement) + X (list) | **3** |

**Subtotal: 17 CFP** (5 processes).

> The sibling-Read from the order trigger is what distinguishes 19a/19c (4 CFP) from the
> plain 3-CFP create/edit pattern of the other objects.
