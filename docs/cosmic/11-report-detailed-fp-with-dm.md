# FP11 — Report: Detailed FP with Data Movements

> [GSM index](./GSM-overview.md) · [Data groups](./data-groups.md)
> COSMIC v5.0 Part 1 §4 (RULE 10, 16–18)

| | |
|---|---|
| **Triggering event** | Analyst runs the "Detailed FP with DM" report |
| **Functional user** | Analyst |
| **FUR source** | `reports/CosmicFunctionPoints/Detailed_FP_with_DM_D9h.report-meta.xml` (Summary, FP↔DM join) |
| **Layer** | Application |

## Description

A summary report joining Functional Process to its Data Movements, showing movement type,
data-group name, implementation category and order. The analyst requests it and the report
engine returns the grouped result set.

## Data movements

| Order | Movement | Type | Data Group | Note |
|---|---|---|---|---|
| 1 | Request report | **E** | Functional Process | Run / refresh |
| 2 | Read Functional Processes | **R** | Functional Process | Grouping rows |
| 3 | Read Data Movements | **R** | Data Movement | Detail rows |
| 4 | Return report output | **X** | Data Movement | Rendered summary report |

## Size

**4 CFP** (1E + 2R + 1X).
