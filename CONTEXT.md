# CosmicWorkBench

A Salesforce DX project for cataloguing and estimating functional processes — capturing what a system does, which data moves, and how much effort each step requires.

## Language

**System Context**:
A bounded domain or application area within the overall architecture (e.g. "Sales Cloud", "PSS", "Custom Platform"). Groups related Functional Processes.
_Avoid_: System, context, domain (ambiguous alone)

**Functional Process**:
A discrete business operation within a System Context — a named sequence of Data Movements that together accomplish a single user or system goal.
_Avoid_: Process, function, flow (flow is a Salesforce automation type)

**Data Movement**:
A single step within a Functional Process — a typed, ordered operation that reads or writes data (e.g. a query, DML, API call). The atomic unit of a Functional Process.
_Avoid_: Step, operation, action (ambiguous)

**Replication**:
Copying a Functional Process or Data Movement from one System Context into another, preserving provenance (source FP, source DM, source SC). The source record is not modified or removed.
_Avoid_: Move, migration, transfer (all imply source is removed)

**Provenance**:
The traceable link from a replicated Functional Process or Data Movement back to its origin — capturing which source FP and DM it was copied from. Stored as lookup fields.
_Avoid_: Lineage (acceptable alias), origin, source

**Source Functional Process**:
The Functional Process that a replicated FP was copied from. Stored as a self-lookup on `cfp_FunctionalProcess__c`.
_Avoid_: Parent process, template process

## Decisions

- `cfp_is_reUsed__c` on both `cfp_FunctionalProcess__c` and `cfp_Data_Movements__c` is a formula field derived from the presence of a source provenance lookup — not a user-managed checkbox. A record is "reused" if and only if it points to a source.
- `cfp_FunctionalProcess__c` gets a new self-lookup `cfp_Reused_from_Functional_Process__c` — mirrors the identically-named field on `cfp_Data_Movements__c`. The replicated FP points to its source FP.
- The Replication flow is launched from the System Context flexipage — the target SC is the page's `recordId`. The user selects only the source Functional Process.
- The source FP picker applies no filters — any FP from any SC is selectable, including FPs already in the target SC or FPs previously replicated there.
- Replicating a source FP with zero Data Movements is permitted — creates the FP record with no DMs.
- When replicating a Functional Process, writable fields clone from source: `Name`, `cfp_triggeringevent__c`, `cfp_Texttual_Overview__c`, `cfp_Sub_System__c`, `cfp_Early_And_Rapid_Estimation_Size__c`. `cfp_System_Context__c` is set to the target SC. `cfp_Order__c` is left blank. Formula and rollup fields auto-derive. `cfp_External_Id__c` is not copied.
</content>
</invoke>