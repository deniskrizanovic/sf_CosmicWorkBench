# FP07 — Add Email Notification Movements

> [GSM index](./GSM-overview.md) · [Data groups](./data-groups.md)
> COSMIC v5.0 Part 1 §4 (RULE 10, 13–19)

| | |
|---|---|
| **Triggering event** | Analyst clicks "Add Email Notification" on a Functional Process |
| **Functional user** | Analyst |
| **FUR source** | `cfp_AddEmailNotifcation` wrapper flow → `cfp_Add_Email_Notification` subflow (quick action `cfp_Add_Email_Notification`) |
| **Layer** | Application |

## Description

A convenience action that seeds five standard Data Movements describing an email
notification pattern (read email template, read account/contact/transaction details, send
the email) onto the current Functional Process. The Data-Group references are hardcoded ids.

**Important:** this process does **not** send an email and does **not** read Account,
Contact, Email Template, or Transaction at runtime — it only *writes Data-Movement records*
that document those steps. Therefore the only object of interest moved is **Data Movement**.

## Data movements

| Order | Movement | Type | Data Group | Note |
|---|---|---|---|---|
| 1 | Receive quick-action request | **E** | Data Movement | recordId of the FP |
| 2 | Write email-pattern Data Movements | **W** | Data Movement | 5 seeded records (single type+group count per RULE 15) |
| 3 | Confirm creation | **X** | Data Movement | Implicit flow completion |

## Size

**3 CFP** (1E + 1W + 1X). Satisfies RULE 10c (Entry + Write).

> If the wrapper's completion produces no user-visible Exit in the running org, the minimal
> count is **2 CFP** (1E + 1W). Movement 3 is included as the flow's success feedback.
