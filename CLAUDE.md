# CLAUDE.md — sf_CosmicWorkBench

## Project

Salesforce DX project. API version 66.0. Source in `force-app/` (default) and `src/`.

## Communication Style

Caveman ultra. Always on. Off only on "stop caveman"/"normal mode".

Rules: drop articles/filler/pleasantries/hedging. Abbrev (DB/auth/config/req/res/fn/impl). Strip conjunctions. Arrows for causality (X -> Y). One word when enough. Fragments OK. Technical terms exact. Code/commits/PRs normal.

Pattern: `[thing] [action] [reason]. [next step].`

Not: "Sure! I'd be happy to help you with that."
Yes: "Bug auth middleware. Token expiry `<` not `<=`. Fix:"

Exception: security warnings, irreversible ops, ambiguous multi-step sequences -> full sentences. Resume ultra after.

## Git Workflow

- Check branch before any edit: `git branch --show-current`
- **Never edit on `main` or `master`** — tell user to create feature branch first
- Feature branch → commit → push → merge to main → push main → delete branch
- Conventional commits: `type[scope]: description` (feat/fix/docs/refactor/chore/etc.)
- Never use `--no-verify` unless user explicitly asks

## Plans

- Store in `.cursor/plans/`
- Filename: `YYYY-MM-DD-<description>.plan.md`
- Each decision in `## Decisions` MUST include at least one worst-case scenario (e.g. "50 records across 8 SCs — how does user find the right one?")
- **Mandatory gate: grill the plan before implementation starts.** Use `grill-with-docs` skill. No code or metadata until grilling is complete and plan is updated.

## Salesforce Skills — MANDATORY

**THIS IS NON-NEGOTIABLE. NO EXCEPTIONS.**

Any task touching Salesforce — metadata, flows, Apex, LWC, objects, fields, permission sets, deployments, queries, configs — MUST invoke the matching skill via the `Skill` tool BEFORE any other action, including clarifying questions.

Available Salesforce skills include (not exhaustive):
`generating-flow`, `generating-apex`, `generating-apex-test`, `generating-custom-object`, `generating-custom-field`, `generating-permission-set`, `generating-lwc-component`, `generating-lightning-app`, `generating-flexipage`, `generating-validation-rule`, `generating-list-view`, `diff-org-changes`, `switching-org`, `deploying-ui-bundle`, and more.

**If no exact skill matches: invoke `find-skills` to discover one. If truly none exists: proceed but note the gap.**

Failure to invoke a skill for a Salesforce task = instruction violation.

## Metadata Generation (Salesforce)

Follow the gate sequence in `.claude/rules/a4v-expert-global-rule.md`:
1. **Initial Gate**: skill selection → print status line
2. **App-Level Gate** (if app intent): load app skill, identify types + order
3. **Per-Type Loop** for each metadata type:
   a. Load skill
   b. Attempt `salesforce-api-context` MCP tools
   c. Pre-write gate (confirm skill + MCP status recorded)
   d. Generate files
   e. Checkpoint before next type

Never write metadata without a loaded skill. Never skip MCP attempt.

### Flow screen components

When a flow screen uses any `flowruntime:` or LWC component, verify output attribute names before writing XML — via skill, MCP, or component source. Never infer from memory. Record verification in pre-write gate.

### New fields → permission set access

After generating any new custom field:
1. Run `find src/main/default/permissionsets force-app -name "*.permissionset-meta.xml"` to discover all permission sets in the repo
2. Present the list to the user
3. User selects which sets need access
4. Update only the approved sets before proceeding

## Commands

| Command | Description |
|---------|-------------|
| `/commit-push-done` | Stage, commit, push, merge to main, cleanup branch |
| `/diff-org-changes` | Compare org metadata vs local source (runs `scripts/diff/diff_org_changes.py`) |

## Scripts

| Script | Usage |
|--------|-------|
| `scripts/diff/diff_org_changes.py --org <alias> [--file <path>]` | Diff org vs local. File relative to `main/default/` |
| `scripts/data/export-data.sh` | Export data |
| `scripts/data/import-data.sh` | Import data |

## Diff Output Format

When presenting org vs local diffs:
1. Per-file table grouped by: Apex, Dashboard, Flows, Object fields, Object metadata, Permission set, Reports
2. Impact summary table: Cosmetic / Functional / Metadata / Permission set / Reports
3. Single-file diffs: include brief interpretation

## Linting & Testing

```bash
npm run lint          # ESLint on aura/lwc JS
npm run test:unit     # LWC Jest tests
npm run prettier      # Format all files
```

Pre-commit hooks run prettier + eslint + jest (via lint-staged + husky).

## Key Paths

- `force-app/` — default package source
- `src/main/default/` — retrieved/deployed metadata
- `scripts/diff/` — org vs local diff toolchain
- `scripts/data/` — data export/import/prep + Apex data ops
- `.cursor/rules/` — Cursor rules (caveman, git-workflow, plans)
- `.cursor/skills/` — skill definitions (caveman, diff-org-changes)
- `.cursor/plans/` — implementation plans
- `.claude/rules/` — Claude rules (a4v-expert-global-rule)