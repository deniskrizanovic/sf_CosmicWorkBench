# FP03 — Copy Functional Process

> [GSM index](./GSM-overview.md) · [Data groups](./data-groups.md)
> COSMIC v5.0 Part 1 §4 (RULE 10, 13–19)

| | |
|---|---|
| **Triggering event** | Analyst launches the Copy Process screen flow |
| **Functional user** | Analyst |
| **FUR source** | `cfp_copyProcess` screen flow |
| **Layer** | Application |

## Description

The analyst picks a target System Context, names the copy, selects a source Functional
Process within that context, and multi-selects which of its Data Movements to duplicate.
The flow creates a Functional Process record and duplicates the selected movements into it,
then confirms.

## Data movements

| Order | Movement | Type | Data Group | Note |
|---|---|---|---|---|
| 1 | Receive copy request + target name | **E** | Functional Process | Analyst input across the screens |
| 2 | Read System Contexts | **R** | System Context | Populate target-context picker |
| 3 | Read source Functional Processes | **R** | Functional Process | Filtered by chosen context |
| 4 | Read source Data Movements | **R** | Data Movement | order < 90, order ≠ 1 |
| 5 | Display selectable movements | **X** | Data Movement | Datatable screens |
| 6 | Write copied Functional Process | **W** | Functional Process | The new record |
| 7 | Write copied Data Movements | **W** | Data Movement | N duplicated records |
| 8 | Confirm completion | **X** | Functional Process | Success screen |

## Size

**8 CFP** (1E + 3R + 2X + 2W).
