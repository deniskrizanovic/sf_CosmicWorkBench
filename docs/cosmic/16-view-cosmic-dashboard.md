# FP16 — View Cosmic Dashboard

> [GSM index](./GSM-overview.md) · [Data groups](./data-groups.md)
> COSMIC v5.0 Part 1 §4 (RULE 10, 16–18)

| | |
|---|---|
| **Triggering event** | Analyst opens / refreshes the Cosmic Dashboard |
| **Functional user** | Analyst |
| **FUR source** | `dashboards/CosmicDashboard/...dashboard-meta.xml` (source reports in CosmicFunctionPoints) |
| **Layer** | Application |

## Description

The dashboard aggregates the sizing reports into charts (total function points,
implementation-category splits, completion status). Opening or refreshing it runs the
source reports and renders the components.

## Data movements

| Order | Movement | Type | Data Group | Note |
|---|---|---|---|---|
| 1 | Request dashboard | **E** | Functional Process | Open / refresh |
| 2 | Read Functional Processes | **R** | Functional Process | Via source reports |
| 3 | Read Data Movements | **R** | Data Movement | Via source reports |
| 4 | Render dashboard components | **X** | Functional Process | Charts / gauges |

## Size

**4 CFP** (1E + 2R + 1X).

> The dashboard reads through its source reports rather than issuing independent queries;
> the objects of interest moved are still Functional Process and Data Movement.
