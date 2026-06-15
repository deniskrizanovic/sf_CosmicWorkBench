# Plan: Bundle diff-org-changes scripts into portable skill

## Context

`diff-org-changes` skill currently references scripts at `scripts/diff/` inside CosmicWorkBench — making it project-specific. Goal: bundle all 3 scripts into the user-level skill directory so the skill is self-contained and works from any project or Cursor/Claude Code session.

## Current State

| Location | Exists? |
|----------|---------|
| `~/.claude/skills/diff-org-changes/SKILL.md` | ✅ |
| `.cursor/skills/diff-org-changes/SKILL.md` | ✅ (project-only) |
| `~/.cursor/skills/diff-org-changes/` | ❌ |
| `~/.cursor/commands/diff-org-changes.md` | ❌ |
| Scripts live in: `scripts/diff/diff-org-changes.sh`, `ensure-active-flow-versions.py`, `normalise-flow.py` | project-only |

## Key Problem: REPO_ROOT Derivation

The script currently derives `REPO_ROOT` from `$SCRIPT_DIR` (up from `scripts/diff/` to repo root). Once moved to `~/.claude/skills/.../scripts/`, that logic breaks.

Fix: change the script to derive `REPO_ROOT` from `$PWD` (caller's working directory) instead of `$SCRIPT_DIR`. Claude/Cursor always invokes from the project root.

## Decisions

### Bundle scripts into skill dir vs. keep in-repo
**Decision:** Bundle into user-level skill dirs (`~/.claude/skills/diff-org-changes/scripts/` and `~/.cursor/skills/diff-org-changes/scripts/`).
**Worst case:** Script is updated in one location but not the other — drift between Claude and Cursor copies. Mitigation: keep `scripts/diff/` as source of truth; note in both skill files that CosmicWorkBench's `scripts/diff/` is canonical for updates.

### REPO_ROOT: $PWD vs arg vs auto-detect
**Decision:** Use `$PWD` — Claude/Cursor always invokes from repo root.
**Worst case:** User invokes from a subdirectory — `REPO_ROOT` is wrong, `src/main/default/` not found. Script will fail with clear "directory not found" error. Acceptable.

## Steps

### 1. Patch `REPO_ROOT` in project's `diff-org-changes.sh`
Current line (approx):
```bash
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
```
Change to:
```bash
REPO_ROOT="$PWD"
```
File: `scripts/diff/diff-org-changes.sh`

### 2. Create `~/.claude/skills/diff-org-changes/scripts/`
Copy all 3 files from `scripts/diff/`:
- `diff-org-changes.sh` (patched version)
- `ensure-active-flow-versions.py`
- `normalise-flow.py`

### 3. Update `~/.claude/skills/diff-org-changes/SKILL.md`
Change script invocation path to:
```bash
KEEP_DIFF_TMP=1 bash ~/.claude/skills/diff-org-changes/scripts/diff-org-changes.sh <org>
```

### 4. Create `~/.cursor/skills/diff-org-changes/scripts/`
Copy same 3 files (separate copy — no cross-tool symlinks).

### 5. Create `~/.cursor/skills/diff-org-changes/SKILL.md`
Mirror of Claude skill, with Cursor-style formatting and path:
```bash
KEEP_DIFF_TMP=1 bash ~/.cursor/skills/diff-org-changes/scripts/diff-org-changes.sh <org>
```

### 6. Create `~/.cursor/commands/diff-org-changes.md`
User-level Cursor command definition (mirrors project-level `.cursor/commands/diff-org-changes.md`).

### 7. Update project-level Cursor skill (optional)
`.cursor/skills/diff-org-changes/SKILL.md` can be removed or left as-is. Project-level takes precedence in Cursor so it still works — but it becomes redundant.

## Critical Files

| File | Action |
|------|--------|
| `scripts/diff/diff-org-changes.sh` | Patch `REPO_ROOT` line |
| `scripts/diff/ensure-active-flow-versions.py` | Source — copy as-is |
| `scripts/diff/normalise-flow.py` | Source — copy as-is |
| `~/.claude/skills/diff-org-changes/SKILL.md` | Update script invocation path |
| `~/.claude/skills/diff-org-changes/scripts/` (new) | 3 script files |
| `~/.cursor/skills/diff-org-changes/SKILL.md` (new) | Full skill definition |
| `~/.cursor/skills/diff-org-changes/scripts/` (new) | 3 script files |
| `~/.cursor/commands/diff-org-changes.md` (new) | Command definition |

## Verification

1. `cd` into a different project (not CosmicWorkBench)
2. Run: `bash ~/.claude/skills/diff-org-changes/scripts/diff-org-changes.sh home-denispoc`
3. Verify script finds `src/main/default/` under `$PWD`
4. In Claude Code session outside CosmicWorkBench → `/diff-org-changes` → skill triggers, absolute path resolves
5. In Cursor outside CosmicWorkBench → `/diff-org-changes` → same
6. Inside CosmicWorkBench: still works (project-level Cursor skill takes precedence if kept)
