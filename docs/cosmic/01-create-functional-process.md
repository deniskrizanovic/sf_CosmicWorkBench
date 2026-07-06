# FP01 — Create Functional Process

> [GSM index](./GSM-overview.md) · [Data groups](./data-groups.md)
> COSMIC v5.0 Part 1 §4 (RULE 10, 13–19)

| | |
|---|---|
| **Triggering event** | Analyst saves a Functional Process record for the first time |
| **Functional user** | Analyst |
| **FUR source** | OOTB record create (`cfp_FunctionalProcess__c`) + `cfp_addDefaultDMsToFuncProcess` autolaunched flow (record-triggered on create) + `cfp_DataMovementOrderSetter` trigger |
| **Layer** | Application |

## Description

The analyst enters the details of a Functional Process and saves it. On save the
record is written, then the record-triggered `cfp_addDefaultDMsToFuncProcess` flow seeds a
standard set of Data Movements (Trigger Entry, three OOTB Write housekeeping movements, a
status/error Exit) by reading the "Salesforce Platform Features" System Context and the
matching Data-Group entities. The order-setting trigger renumbers the seeded movements.

Per the agreed rule, the seeding flow and the order trigger have **no independent
triggering event** — they fire inside this single analyst-initiated save — so their unique
data movements are folded in here rather than modelled as separate processes.

## Data movements

| Order | Movement | Type | Data Group | Note |
|---|---|---|---|---|
| 1 | Receive Functional Process attributes | **E** | Functional Process | Analyst-entered data |
| 2 | Read System Context "Salesforce Platform Features" | **R** | System Context | Seeding flow lookup |
| 3 | Read seed Data-Group entities | **R** | Data Group | Seeding flow looks up Trigger / Full-Text / Field-History / Event-Monitoring / status groups |
| 4 | Write Functional Process | **W** | Functional Process | The saved FP record |
| 5 | Write seeded Data Movements | **W** | Data Movement | 5 default movement records (trigger renumbers them — same data group, no extra count per RULE 14/15) |
| 6 | Confirm save to analyst | **X** | Functional Process | Save confirmation / record view |

## Size

**6 CFP** (1E + 2R + 2W + 1X).

RULE 14/15 dedup applied: the order-renumber trigger's Write of Data Movement collapses
into movement 5; its Read of sibling Data Movements is not unique here because no distinct
sibling data group exists beyond the ones just written.
