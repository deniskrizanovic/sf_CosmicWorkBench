# FP06 — Replicate Functional Process to Context

> [GSM index](./GSM-overview.md) · [Data groups](./data-groups.md)
> COSMIC v5.0 Part 1 §4 (RULE 10, 13–19)

| | |
|---|---|
| **Triggering event** | Analyst clicks "Replicate FP to Context" on a System Context |
| **Functional user** | Analyst |
| **FUR source** | `cfp_replicateFPToContext` screen flow (quick action `cfp_Replicate_FP_to_Context`) |
| **Layer** | Application |

## Description

From a target System Context, the analyst selects a source System Context and a source
Functional Process. The flow creates a Functional Process in the target context (stamping
reuse-tracking fields) and replicates all of its Data Movements, then reports how many were
created. Distinct from FP03 in that it always copies **all** movements and records
reuse-from links.

## Data movements

| Order | Movement | Type | Data Group | Note |
|---|---|---|---|---|
| 1 | Receive replication request | **E** | Functional Process | recordId (target SC), source SC + FP picks |
| 2 | Read target System Context | **R** | System Context | Confirm target |
| 3 | Read source Functional Process | **R** | Functional Process | Source, with reuse fields |
| 4 | Read source Data Movements | **R** | Data Movement | All movements of source FP |
| 5 | Write replicated Functional Process | **W** | Functional Process | New record + reuse-from link |
| 6 | Write replicated Data Movements | **W** | Data Movement | N records + reuse links |
| 7 | Confirm + report count | **X** | Functional Process | Done screen with DM count |

## Size

**7 CFP** (1E + 3R + 2W + 1X).
