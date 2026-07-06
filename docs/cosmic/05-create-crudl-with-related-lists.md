# FP05 — Create CRUDL with Related Lists

> [GSM index](./GSM-overview.md) · [Data groups](./data-groups.md)
> COSMIC v5.0 Part 1 §4 (RULE 10, 13–19)

| | |
|---|---|
| **Triggering event** | Analyst clicks "Create CRUDL" on a Functional Process |
| **Functional user** | Analyst |
| **FUR source** | `cfp_createCRUDLwithRelatedLists` screen flow (quick action `Create_CRUDL`) |
| **Layer** | Application |

## Description

The analyst selects a "hero" Data-Group entity plus optional list-view / highlights-panel /
path toggles and related-list entities. The flow generates the standard CRUDL scaffold of
Read/Display/Click Data Movements (7+ records depending on toggles) and persists them, then
shows a confirmation of the selections.

## Data movements

| Order | Movement | Type | Data Group | Note |
|---|---|---|---|---|
| 1 | Receive request + scaffold options | **E** | Functional Process | recordId, hero pick, toggles, related lists |
| 2 | Read Functional Process | **R** | Functional Process | Loads System Context relationship |
| 3 | Read Data-Group entities | **R** | Data Group | Filtered by System Context |
| 4 | Display selectable entities | **X** | Data Group | Selection screen |
| 5 | Write scaffold Data Movements | **W** | Data Movement | 7+ generated records (single type+group count per RULE 15) |
| 6 | Confirm selections | **X** | Functional Process | Confirmation screen |

## Size

**6 CFP** (1E + 2R + 2X + 1W).
