# FP09 — Visualise Functional Process

> [GSM index](./GSM-overview.md) · [Data groups](./data-groups.md)
> COSMIC v5.0 Part 1 §4 (RULE 10, 13–19)

| | |
|---|---|
| **Triggering event** | Analyst opens a Functional Process record page (the visualiser component renders) |
| **Functional user** | Analyst |
| **FUR source** | `cfp_FunctionalProcessVisualiser` LWC → `cfp_getDataMovements.getSteps` Apex |
| **Layer** | Application |

## Description

On the Functional Process record page the visualiser LWC requests the process's ordered
Data Movements via Apex and renders them as an SVG sequence diagram (boundary lines,
Entry/Exit/Read/Write arrows). Read-only; delivers a distinct bespoke output beyond the
generic record view.

## Data movements

| Order | Movement | Type | Data Group | Note |
|---|---|---|---|---|
| 1 | Request diagram (recordId) | **E** | Functional Process | Component render / connectedCallback |
| 2 | Read Data Movements | **R** | Data Movement | `getSteps(fpId)`, ordered |
| 3 | Render SVG diagram | **X** | Data Movement | Boundary + movement arrows |

## Size

**3 CFP** (1E + 1R + 1X).
