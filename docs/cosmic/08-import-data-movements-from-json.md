# FP08 — Import Data Movements from JSON

> [GSM index](./GSM-overview.md) · [Data groups](./data-groups.md)
> COSMIC v5.0 Part 1 §4 (RULE 10, 13–19)

| | |
|---|---|
| **Triggering event** | External JSON payload submitted through the importer screen flow |
| **Functional user** | External JSON source (payload provider) + Analyst (operates the screen) |
| **FUR source** | `cfp_DataMovementsJSONImporter` screen flow → `cfp_DataMovementsImporter` invocable Apex |
| **Layer** | Application |

## Description

A Functional Process id, a JSON payload, and a "replace existing" flag are supplied. The
Apex parses the payload, resolves each movement's Data-Group reference by external id,
optionally deletes existing movements for the process, bulk-inserts the movements, and
returns inserted count plus traversal warnings. This is the process where the **External
JSON source** functional user crosses the boundary.

## Data movements

| Order | Movement | Type | Data Group | Note |
|---|---|---|---|---|
| 1 | Receive FP id + JSON payload + replace flag | **E** | Data Movement | Crosses boundary from external source |
| 2 | Read Functional Process | **R** | Functional Process | Resolve System Context name |
| 3 | Read Data-Group entities by external id | **R** | Data Group | Bulk reference resolution |
| 4 | Delete existing Data Movements | **W** | Data Movement | Only if replace flag set (RULE 20 — delete is a Write) |
| 5 | Write imported Data Movements | **W** | Data Movement | Bulk insert — same data group as movement 4, single count per RULE 14 |
| 6 | Return result + traversal warnings | **X** | Data Movement | Inserted count, errors, warnings screen |

## Size

**5 CFP** (1E + 2R + 1W + 1X).

RULE 14 dedup: the conditional Delete (movement 4) and the Insert (movement 5) are both
Writes of the **Data Movement** data group within one process → counted once.
