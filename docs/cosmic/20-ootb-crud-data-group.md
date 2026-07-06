# FP20 — OOTB CRUD: Data Group

> [GSM index](./GSM-overview.md) · [Data groups](./data-groups.md)
> COSMIC v5.0 Part 1 §4 (RULE 10, 13–20)

Standard Salesforce record-page processes for `cfp_DataGroups__c` (DG4).
Implementation category = **OOTB**. Object of interest = Data Group.

The `cfp_DataGroup_ExternalId_BeforeSave` flow fires on Create/Edit. It computes the
external-id from the record's own in-memory attributes — **no** query, **no** separate
storage access — so per §4.3 Note 4 it adds **no** unique data movement (folded into the
Write already counted).

| # | Process | Trigger | Data movements | CFP |
|---|---------|---------|----------------|-----|
| 20a | Create Data Group | Analyst saves a Data Group | E (attributes) + W (Data Group) + X (confirm) | **3** |
| 20b | View Data Group | Analyst opens the record | E (request) + R (Data Group) + X (display) | **3** |
| 20c | Edit Data Group | Analyst saves an edit | E (attributes) + R (Data Group) + W (Data Group) + X (confirm) | **4** |
| 20d | Delete Data Group | Analyst deletes the record | E (request) + W (delete, RULE 20) + X (confirm) | **3** |
| 20e | List Data Groups | Analyst opens a list view | E (request) + R (Data Group) + X (list) | **3** |

**Subtotal: 16 CFP** (5 processes).
