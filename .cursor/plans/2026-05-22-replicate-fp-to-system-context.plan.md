# Plan: Replicate Functional Process to System Context

## Goal

Allow a user to replicate a Functional Process — including all its Data Movements — from any System Context into a target System Context, with full provenance recorded on both the FP and DM records.

Launched from the System Context flexipage. Target SC = `recordId`.

---

## Scope

### 1. New field — `cfp_FunctionalProcess__c`

**`cfp_Reused_from_Functional_Process__c`**
- Type: Lookup → `cfp_FunctionalProcess__c` (self-lookup)
- Delete constraint: SetNull
- Required: false
- Label: Reused from Functional Process
- Mirrors the identically-named field on `cfp_Data_Movements__c`

### 2. Convert `cfp_is_reUsed__c` → formula on `cfp_FunctionalProcess__c`

- Old: Checkbox (default false)
- New: Formula (Text or Checkbox equivalent)
- Formula: `NOT(ISBLANK(cfp_Reused_from_Functional_Process__c))`
- A FP is "reused" if and only if it points to a source FP

### 3. Convert `cfp_is_reUsed__c` → formula on `cfp_Data_Movements__c`

- Old: Checkbox (default false)
- New: Formula (Text or Checkbox equivalent)
- Formula: `NOT(ISBLANK(cfp_Reused_Functional_Step__c))`
- A DM is "reused" if and only if it points to a source DM

### 4. New flow — `cfp_replicateFPToContext`

**Type:** Screen Flow  
**Entry point:** System Context record page action button  
**Input variable:** `recordId` (String) — target SC Id

#### Flow steps

1. **Get target SC** — query `cfp_System_Context__c` by `recordId` (for display name on confirmation screen)
2. **Screen 1 — Pick Source Process**
   - Dropdown: all `cfp_FunctionalProcess__c` records, no filters, sorted by Name
   - Label: "Select the Functional Process to replicate"
3. **Get source FP** — query source FP record (all writable fields)
4. **Get source DMs** — query all `cfp_Data_Movements__c` where `cfp_FunctionalProcess__c = sourceFPId`, ordered by `cfp_order__c`
5. **Screen 2 — Confirmation**
   - Display: source FP name, target SC name, DM count
   - Label: "This will create a new Functional Process in [target SC] with [n] Data Movements."
6. **Create replicated FP**
   - Clone: `Name`, `cfp_triggeringevent__c`, `cfp_Texttual_Overview__c`, `cfp_Sub_System__c`, `cfp_Early_And_Rapid_Estimation_Size__c`
   - Set: `cfp_System_Context__c` = target SC `recordId`
   - Set: `cfp_Reused_from_Functional_Process__c` = source FP Id
   - Leave blank: `cfp_Order__c`, `cfp_External_Id__c`
7. **Loop source DMs → build cloned DM collection**
   - Clone all writable DM fields
   - Set: `cfp_FunctionalProcess__c` = new replicated FP Id
   - Set: `cfp_Reused_from_Functional_Process__c` = source FP Id
   - Set: `cfp_Reused_Functional_Step__c` = source DM Id
8. **Create DMs** — bulk insert cloned DM collection (skip if empty — 0 DMs is valid)
9. **Screen 3 — Done**
   - "Replication complete. [n] Data Movements created."

---

## Decisions

- **Replication = copy + provenance.** Source records are not modified or removed.
- **No filters on source FP picker.** Any FP from any SC is valid, including duplicates to the same target SC.
- **All-or-nothing.** All DMs replicate; no cherry-picking (that's `cfp_copyDMsFromProcess`).
- **`cfp_Order__c` left blank** on replicated FP — ordering in target SC is independent.
- **Estimation fields clone** — `cfp_Early_And_Rapid_Estimation_Size__c` travels with the replication.
- **0 DM source FPs allowed** — confirmation screen shows count; user proceeds at their discretion.
- **`cfp_copyDMsFromProcess` unchanged** — provenance is a Replication concern only.

---

## Build order

1. Field: `cfp_Reused_from_Functional_Process__c` on `cfp_FunctionalProcess__c`
2. Field: convert `cfp_is_reUsed__c` → formula on `cfp_FunctionalProcess__c`
3. Field: convert `cfp_is_reUsed__c` → formula on `cfp_Data_Movements__c`
4. Flow: `cfp_replicateFPToContext`
