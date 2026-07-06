---
name: diff-org-changes
description: Runs a full diff between a Salesforce org and local source, then presents results as grouped tables with an impact summary. Use when the user asks to diff the org, compare org vs local, run an org diff, or check what's changed in the org.
---

# Diff Org Changes

## Workflow

1. Run the diff script with `KEEP_DIFF_TMP=1` so the temp dir survives for reading individual diffs:
   ```bash
   cd "<repo-root>" && KEEP_DIFF_TMP=1 python3 ~/.agents/skills/diff-org-changes/scripts/diff_org_changes.py --org <org-alias> 2>&1
   ```
   Default org alias: `home-denispoc`. Use whatever the user specifies, or the project default.

   Single-file diff:
   ```bash
   cd "<repo-root>" && KEEP_DIFF_TMP=1 python3 ~/.agents/skills/diff-org-changes/scripts/diff_org_changes.py --org <org-alias> --file <path-relative-to-main-default> 2>&1
   ```

2. Check whether `=== Differences ===` appears in the output.
   - **If yes**: parse that section to get the list of changed files and their diff paths, then proceed to step 3.
   - **If no**: the script failed before completing. Show the user the last 20 lines of script output and stop. Do NOT attempt manual diffs. Do NOT use Bash to compare files yourself.

3. Run **one** Bash command that diffs all changed file pairs at once. Build it from the `=== Differences ===` output: for each `Files A and B differ` line, add `echo "=== <label> ===" && diff A B`. Pipe to `| head -80` per diff if files could be large (flows, flexipages). For normalised diffs (org-flows-norm, local-flows-norm, org-obj-norm, local-obj-norm, org-vr-norm, local-vr-norm), use those paths — not the raw retrieved files. Do NOT issue one Bash call per file; combine them all into a single command.

4. Present results as **grouped tables** (see format below). Do NOT dump raw diff output.

**HARD STOP RULES — never do these under any circumstances:**
- Never issue one Read or Bash call per diff file — always batch into a single Bash command
- Never dump raw diff output to the user
- If the script fails, report it and wait for instructions

## Output Format

### Per-type tables

Group by: Apex, Flows, Object fields, Object metadata, Flexipages, Permission sets, Reports, Validation Rules.

Show only categories that have changes. Columns: File/Field | Org vs Local (one-line interpretation).

### Impact summary table

| Category | Cosmetic | Functional | Metadata |
|----------|----------|------------|----------|

### Local-only / Org-only

Separate small tables for files that exist on one side only. Note whether they matter (e.g. tooling config = ignore).

## Rules

- Never dump raw `diff` output — always interpret it.
- One-line interpretation per file: what actually changed (e.g. "quote encoding", "`caseSensitive` flag missing", "Submit button visibility rule reordered").
- Ignore `.DS_Store`, `jsconfig.json`, `tsconfig.json` — note as "tooling/OS artifact".
- After presenting tables, ask: "Want me to drill into any specific file?"

## Normalisation

The script strips known noise before diffing. These are **not real differences**:

| Type | What's stripped |
|------|----------------|
| Flows | `locationX`/`locationY`, `<status>`, element order |
| Apex/Triggers | trailing newline |
| Dashboards | `<owner>`, `<runningUser>` |
| Fields | `&quot;` → `"` |
| Objects | `<recordTypeTrackHistory>` |
| Validation Rules | `<![CDATA[...]]>` → XML entities (`&lt;`, `&gt;`) |

When a validation rule shows `&lt;&gt; (XML entity) in org vs <![CDATA[...]]> in local` — that is functionally identical encoding. The normaliser converts both sides to entity form before diffing, so it will **not appear as a difference** after the fix.
