# FP13 — Report: Functional Processes Size by Subsystem

> [GSM index](./GSM-overview.md) · [Data groups](./data-groups.md)
> COSMIC v5.0 Part 1 §4 (RULE 10, 16–18)

| | |
|---|---|
| **Triggering event** | Analyst runs the "Functional Processes Size by subsystem" report |
| **Functional user** | Analyst |
| **FUR source** | `reports/CosmicFunctionPoints/Functional_Processes_Size_by_subsystem_DFy.report-meta.xml` (Summary, FP↔DM join) |
| **Layer** | Application |

## Description

A summary report grouping total function points by sub-system and implementation category.

## Data movements

| Order | Movement | Type | Data Group | Note |
|---|---|---|---|---|
| 1 | Request report | **E** | Functional Process | Run / refresh |
| 2 | Read Functional Processes | **R** | Functional Process | Grouped by sub-system |
| 3 | Read Data Movements | **R** | Data Movement | Implementation-category detail |
| 4 | Return report output | **X** | Functional Process | Rendered summary report |

## Size

**4 CFP** (1E + 2R + 1X).
