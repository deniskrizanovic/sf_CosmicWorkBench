# sf_CosmicWorkBench

A Salesforce workbench for the **[COSMIC Function Points](https://cosmic-sizing.org/)** software sizing methodology. Models functional processes as ordered data movements, categorised by implementation type (OOTB / Config / Low-Code / Pro-Code), to produce traceable effort estimates.

[![Deploy to Sandbox](https://raw.githubusercontent.com/afawcett/githubsfdeploy/master/deploy.png)](https://githubsfdeploy.herokuapp.com/app/githubdeploy/deniskrizanovic/sf_CosmicWorkbench?ref=main)

---

## Data Model

```
cfp_System_Context__c
  └── cfp_FunctionalProcess__c       (one process per triggering event)
        └── cfp_Data_Movements__c    (Entry / Exit / Read / Write steps)
              └── cfp_DataGroups__c  (data entity referenced by a movement)
```

---

## Functional Processes

### 1. Size a functional process

The core workflow. A user creates a **Functional Process** under a **System Context**, then adds **Data Movements** — each classified as an Entry, Exit, Read, or Write against a **Data Group**. Each movement is tagged with an implementation category (OOTB / Config / Low-Code / Pro-Code) and the artifact that delivers it (component name, flow, class, etc.).

The process record rolls up total CFP counts and splits them by implementation category, giving an immediate size estimate. The `cfp_FunctionalProcessVisualiser` LWC renders the breakdown on the record page; `cfp_DataMovements` provides inline editing of the movement list. An Apex trigger (`cfp_handleOrderSetting`) keeps movement sequence numbers contiguous as steps are added, removed, or reordered.

### 2. Seed a new process with default movements

When creating a process for a common pattern (e.g. a standard CRUD screen), the `cfp_addDefaultDMsToFuncProcess` flow inserts a standard set of Data Movements automatically, saving the analyst from re-entering the same boilerplate each time.

### 3. Copy a process

The `cfp_copyProcess` screen flow duplicates an existing Functional Process — including all its Data Movements — into the same or a different System Context. A lighter variant, `cfp_copyDMsFromProcess`, copies only the movements from one process into another (useful for reuse tracking without full duplication).

### 4. Bulk-import movements from JSON

For migrating estimates from external tools or seeding large processes programmatically, the `cfp_DataMovementsJSONImporter` screen flow accepts a JSON payload and invokes the `cfp_DataMovementsImporter` Apex class to upsert movements in bulk. Supports replace-existing mode and surfaces traversal warnings from the source payload.

### 5. Create a CRUD process with related lists

The `cfp_createCRUDLwithRelatedLists` screen flow guides the analyst through creating a functional process structured around a standard CRUD pattern, automatically wiring up related list references and movement counts.

### 6. Report on sizing across system contexts

Prebuilt reports in the **CosmicFunctionPoints** folder and the **CosmicDashboard** aggregate CFP metrics — total function points, implementation-category splits, reuse flags, completion status — across all processes and system contexts.

### 7. Move data between orgs

SFDMU-based scripts export all CFP records from a source org and import them into a target. The `split-by-system-context.py` script partitions the export into per-System-Context subsets, allowing selective import by project scope.

```bash
./scripts/data/export-data.sh                        # export from org
python3 scripts/data/split-by-system-context.py      # split by system context
./scripts/data/import-data.sh                        # import to org
```

### 8. Diff org metadata against local source

For orgs without source tracking, `diff-org-changes.sh` retrieves current metadata from the org into a temp directory and diffs it against `src/main/default/`. Flows are normalised before diffing to remove noise. Supports full-org or single-file mode.

```bash
./scripts/diff/diff-org-changes.sh <org-alias>
./scripts/diff/diff-org-changes.sh <org-alias> classes/cfp_DataMovementsImporter.cls
```

---

## Setup

### Prerequisites

- [Salesforce CLI](https://developer.salesforce.com/tools/salesforcecli) (`sf`)
- Node.js 18+
- Python 3
- [SFDMU plugin](https://github.com/forcedotcom/SFDX-Data-Move-Utility) (`sf plugins install sfdmu`)

### Deploy

```bash
npm install
sf org login web --alias <your-alias> --instance-url https://your-org.sandbox.my.salesforce.com
sf project deploy start --source-dir src --target-org <your-alias>
sf org assign permset --name cfp_CosmicWorkbench --target-org <your-alias>
```

### Lint & test

```bash
npm run lint          # ESLint on LWC JavaScript
npm run test:unit     # LWC Jest unit tests
npm run prettier      # Format all source files
```

Pre-commit hooks (Husky + lint-staged) run Prettier, ESLint, and Jest automatically on staged files.
