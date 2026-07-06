# Move diff-org-changes skill to dk-skills repo

**Date:** 2026-06-17

## Goal

Move `diff-org-changes` skill from `~/.claude/skills/diff-org-changes/` (manually installed, Claude Code + Cursor only) to `github.com/deniskrizanovic/dk-skills` (installed via `npx skills add`, all agents).

**Source of truth after:** `dk-skills.git`
**Install path after:** `~/.agents/skills/diff-org-changes/`

## Decisions

| Decision | Choice |
|----------|--------|
| After move, keep copy in `~/.claude/skills/`? | No — delete it |
| Hardcoded script path in SKILL.md | Update to `~/.agents/skills/diff-org-changes/scripts/diff_org_changes.py` |
| Project-level `.cursor/skills/diff-org-changes/SKILL.md` | Delete it |

## Steps

### 1. Scaffold `dk-skills` repo locally

```bash
mkdir ~/projects/dk-skills
cd ~/projects/dk-skills
git init
git remote add origin https://github.com/deniskrizanovic/dk-skills.git
```

### 2. Create skill subdirectory and copy files

```bash
mkdir -p ~/projects/dk-skills/diff-org-changes/scripts
cp ~/.claude/skills/diff-org-changes/SKILL.md ~/projects/dk-skills/diff-org-changes/SKILL.md
cp ~/.claude/skills/diff-org-changes/scripts/diff_org_changes.py ~/projects/dk-skills/diff-org-changes/scripts/diff_org_changes.py
```

### 3. Update hardcoded path in SKILL.md

In `~/projects/dk-skills/diff-org-changes/SKILL.md`, replace:

```
python3 ~/.claude/skills/diff-org-changes/scripts/diff_org_changes.py
```

with:

```
python3 ~/.agents/skills/diff-org-changes/scripts/diff_org_changes.py
```

Two occurrences (full diff and single-file diff commands).

### 4. Commit and push to GitHub

```bash
cd ~/projects/dk-skills
git add .
git commit -m "feat(diff-org-changes): add skill with Python diff script"
git branch -M main
git push -u origin main
```

### 5. Install via npx skills

```bash
npx skills add deniskrizanovic/dk-skills@diff-org-changes -g -y
```

Verify installed at `~/.agents/skills/diff-org-changes/`.

### 6. Smoke-test the skill

Open a new Claude Code session in `sf_CosmicWorkBench`. Run `/diff-org-changes` and confirm it resolves to the skill and invokes the Python script from the new path.

### 7. Remove old installations

```bash
# Remove from ~/.claude/skills/
rm -rf ~/.claude/skills/diff-org-changes

# Remove project-level Cursor copy
rm /Users/dkrizanovic/projects/sf_CosmicWorkBench/.cursor/skills/diff-org-changes/SKILL.md
rmdir /Users/dkrizanovic/projects/sf_CosmicWorkBench/.cursor/skills/diff-org-changes
```

**Do step 7 only after step 6 confirms the new install works.**

### 8. Commit removal from sf_CosmicWorkBench

```bash
cd /Users/dkrizanovic/projects/sf_CosmicWorkBench
git add .cursor/skills/diff-org-changes/
git commit -m "chore(skills): remove project-level diff-org-changes (moved to dk-skills repo)"
```

## Verification checklist

- [ ] `~/.agents/skills/diff-org-changes/SKILL.md` exists
- [ ] `~/.agents/skills/diff-org-changes/scripts/diff_org_changes.py` exists
- [ ] Path in SKILL.md points to `~/.agents/skills/...`
- [ ] `npx skills ls -g` shows `diff-org-changes` from `~/.agents/skills/diff-org-changes`
- [ ] `~/.claude/skills/diff-org-changes/` deleted
- [ ] `.cursor/skills/diff-org-changes/` deleted
- [ ] `dk-skills` repo pushed to GitHub
