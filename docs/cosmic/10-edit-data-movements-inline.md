# FP10 — Edit Data Movements Inline

> [GSM index](./GSM-overview.md) · [Data groups](./data-groups.md)
> COSMIC v5.0 Part 1 §4 (RULE 10, 16–17)

| | |
|---|---|
| **Triggering event** | Analyst edits rows in the inline Data-Movements table and saves |
| **Functional user** | Analyst |
| **FUR source** | `cfp_DataMovements` LWC |
| **Layer** | Application |

## Description

An editable datatable lets the analyst add/edit movement rows, reorder them (Move Up/Down),
and Save. On save the component validates movement type and implementation category and
shows a success toast or field-level errors.

> **⚠ No persistence.** As shipped, this LWC is **entirely client-side**: it calls no Apex
> and never writes to the database. Rows live in an in-memory array; Save only validates and
> re-renders. It therefore performs **no Read and no Write** of persistent storage. Modelled
> here honestly as Entry + Exit (satisfies RULE 10c: Entry + Exit). Likely prototype /
> unfinished. If persistence is added later, add a **W — Data Movement** and this becomes 3+ CFP.

## Data movements

| Order | Movement | Type | Data Group | Note |
|---|---|---|---|---|
| 1 | Receive edited movement rows | **E** | Data Movement | Inline edits + Add row |
| 2 | Return validation result / toast | **X** | Data Movement | Field errors or success feedback |

## Size

**2 CFP** (1E + 1X) — minimum valid process size (RULE 10c).
