# Data Groups & Objects of Interest

> Part of the [Generic Software Model](./GSM-overview.md) for **sf_CosmicWorkBench**.
> Grounded in COSMIC Measurement Manual v5.0, Part 1 §4.3 (RULE 11).

Per **RULE 11**, each data group is unique through its collection of data attributes and
maps to exactly one object of interest in the world of a functional user. The software
being measured reads and writes records **of its own four custom objects** at runtime, so
these are the objects of interest.

| # | Data Group | Salesforce object | Object of interest (analyst's world) | Key attributes |
|---|------------|-------------------|--------------------------------------|----------------|
| DG1 | **System Context** | `cfp_System_Context__c` | A system / business domain being sized | Name, Description, External Id |
| DG2 | **Functional Process** | `cfp_FunctionalProcess__c` | One process per triggering event | Name, Triggering event, Sub-system, Textual overview, Early&Rapid size, roll-up sums |
| DG3 | **Data Movement** | `cfp_Data_Movements__c` | An Entry/Exit/Read/Write step within a process | Name, Movement type (E/R/W/X), Implementation category, Data Group ref, Order, Artifact name, Comments, reuse flags |
| DG4 | **Data Group (entity)** | `cfp_DataGroups__c` | A data entity a movement acts on | Object name, Attributes, System Context, External Id |

## Notes on boundaries

- The **Salesforce platform database** is *persistent storage* across the boundary, not a
  functional user. Reads/Writes of the four objects above cross the process ↔ storage
  boundary.
- The **`cfp_External_Id__c`** field on DG1/DG2/DG3/DG4 is an implementation-derived key
  (computed `{systemContext|objectName}`). Per **§4.3 Note 4**, data resulting only from
  the implementation is not itself an object of interest — the external-id
  before-save computation adds **no** unique data movement (it manipulates the record's own
  in-memory attributes during a Write already counted).
- Standard platform entities the app *mentions but does not move* (Email Template, Account,
  Contact, "Transaction") are **not** data groups: the email-notification process only
  creates Data-Movement records *describing* them; it does not read those entities at
  runtime. See [07-add-email-notification.md](./07-add-email-notification.md).

## Data groups NOT counted

| Candidate | Why excluded |
|-----------|--------------|
| External Id key | Implementation-derived (§4.3 Note 4) |
| `order` sequence number | Implementation-derived ordering; the renumber trigger's *Write* of Data Movement collapses into the enclosing process's existing Data-Movement Write (RULE 14/15) |
| Email Template / Account / Contact / Transaction | App does not read these at runtime; only records movements about them |
