# FP04 — Copy Data Movements from Process

> [GSM index](./GSM-overview.md) · [Data groups](./data-groups.md)
> COSMIC v5.0 Part 1 §4 (RULE 10, 13–19)

| | |
|---|---|
| **Triggering event** | Analyst clicks "Copy DMs from Process" on a Functional Process |
| **Functional user** | Analyst |
| **FUR source** | `cfp_copyDMsFromProcess` screen flow (quick action `cfp_Copy_DMs_from_Process`) |
| **Layer** | Application |

## Description

From the current Functional Process, the analyst chooses a source process (same System
Context by default, or all processes if widened), selects which source Data Movements to
clone, and picks the insertion point. The flow clones the selected movements into the
current process; the order trigger adjusts sequence numbers.

## Data movements

| Order | Movement | Type | Data Group | Note |
|---|---|---|---|---|
| 1 | Receive quick-action request + choices | **E** | Data Movement | recordId, source-process pick, insertion order, selection |
| 2 | Read candidate Functional Processes | **R** | Functional Process | Current + optionally all in context |
| 3 | Read source Data Movements | **R** | Data Movement | order < 90 |
| 4 | Display selectable movements | **X** | Data Movement | Datatable screen |
| 5 | Write cloned Data Movements | **W** | Data Movement | N cloned records (order trigger renumbers — same group, no extra count) |
| 6 | Confirm completion | **X** | Data Movement | Done screen |

## Size

**6 CFP** (1E + 2R + 2X + 1W).
