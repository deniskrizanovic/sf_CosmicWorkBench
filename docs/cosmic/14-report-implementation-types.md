# FP14 — Report: Implementation Types

> [GSM index](./GSM-overview.md) · [Data groups](./data-groups.md)
> COSMIC v5.0 Part 1 §4 (RULE 10, 16–18)

| | |
|---|---|
| **Triggering event** | Analyst runs the "Implementation Types" report |
| **Functional user** | Analyst |
| **FUR source** | `reports/CosmicFunctionPoints/Implementation_Types_GxC.report-meta.xml` (Summary, FP↔DM join) |
| **Layer** | Application |

## Description

A summary report grouping Data Movements by System Context and implementation type.

## Data movements

| Order | Movement | Type | Data Group | Note |
|---|---|---|---|---|
| 1 | Request report | **E** | Functional Process | Run / refresh |
| 2 | Read Functional Processes | **R** | Functional Process | Provides System Context grouping |
| 3 | Read Data Movements | **R** | Data Movement | Implementation-type detail |
| 4 | Return report output | **X** | Data Movement | Rendered summary report |

## Size

**4 CFP** (1E + 2R + 1X).
