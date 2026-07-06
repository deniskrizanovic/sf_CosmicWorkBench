# FP02 — Create Read+Display Pair

> [GSM index](./GSM-overview.md) · [Data groups](./data-groups.md)
> COSMIC v5.0 Part 1 §4 (RULE 10, 13–19)

| | |
|---|---|
| **Triggering event** | Analyst clicks "Create ReadDisplayPair" on a Functional Process |
| **Functional user** | Analyst |
| **FUR source** | `cfp_createReadAndDisplayMovements` screen flow (quick action `cfp_Create_ReadDisplayPair`) |
| **Layer** | Application |

## Description

From a Functional Process, the analyst launches a screen flow that lists the Data-Group
entities belonging to the process's System Context. The analyst multi-selects entities;
for each, the flow creates a **Read** movement and a paired **Display (Exit)** movement,
persists them, and shows a confirmation.

## Data movements

| Order | Movement | Type | Data Group | Note |
|---|---|---|---|---|
| 1 | Receive quick-action request (recordId) | **E** | Functional Process | Analyst triggers the action |
| 2 | Read available Data-Group entities | **R** | Data Group | Filtered by the FP's System Context |
| 3 | Display selectable entities | **X** | Data Group | Datatable screen |
| 4 | Write Read/Display movements | **W** | Data Movement | Two records per selected entity (one type+group → 1 count per RULE 15) |
| 5 | Confirm creation to analyst | **X** | Data Movement | Success screen/toast |

## Size

**5 CFP** (1E + 1R + 2X + 1W).
