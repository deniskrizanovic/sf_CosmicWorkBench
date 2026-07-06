# FP12 — Report: Functional Processes Size

> [GSM index](./GSM-overview.md) · [Data groups](./data-groups.md)
> COSMIC v5.0 Part 1 §4 (RULE 10, 16–18)

| | |
|---|---|
| **Triggering event** | Analyst runs the "Functional Processes Size" report |
| **Functional user** | Analyst |
| **FUR source** | `reports/CosmicFunctionPoints/Functional_Processes_Size_Xeu.report-meta.xml` (Tabular, FP↔DM join) |
| **Layer** | Application |

## Description

A tabular report listing each Functional Process with its total function points and the
per-category sums (OOTB / Config / Low-Code / Pro-Code) and completeness flag.

## Data movements

| Order | Movement | Type | Data Group | Note |
|---|---|---|---|---|
| 1 | Request report | **E** | Functional Process | Run / refresh |
| 2 | Read Functional Processes | **R** | Functional Process | Row per FP + roll-up fields |
| 3 | Read Data Movements | **R** | Data Movement | Join source for the report type |
| 4 | Return report output | **X** | Functional Process | Rendered tabular report |

## Size

**4 CFP** (1E + 2R + 1X).
