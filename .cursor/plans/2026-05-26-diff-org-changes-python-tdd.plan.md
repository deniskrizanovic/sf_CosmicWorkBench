# Plan: Migrate diff-org-changes.sh to Python (TDD)

## Decisions

| # | Decision | Worst-case |
|---|----------|------------|
| 1 | Fixture-based tests: real temp dirs, mocked `sf` subprocess | Mocked subprocess still misses CLI flag changes — mitigated by asserting exact call args |
| 2 | Absorb `normalise-flow.py` + `ensure-active-flow-versions.py` into new module | Docs referencing standalone scripts break — update SKILL.md and CLAUDE.md as part of migration |
| 3 | Single file: `scripts/diff/diff_org_changes.py` | File grows past ~400 lines — refactor to package at that point |
| 4 | `argparse` with `--org` (default `home-denispoc`) and `--file` | Skill invocation in SKILL.md breaks — update skill doc in same PR |
| 5 | pytest in `scripts/diff/tests/`, `pyproject.toml` at repo root | No Python config exists yet — add minimal `pyproject.toml` |
| 6 | Injectable `runner=subprocess.run` on all shell-out functions | See ADR `docs/adr/0001-injectable-runner-for-subprocess.md` |
| 7 | Test units 1–7 + 10 directly; 8–9 assert call args only; 11 smoke test | Smoke test masks integration bugs — accepted, live-org test is out of scope |

## Units to implement

| # | Function | Notes |
|---|----------|-------|
| 1 | `detect_package_dir(project_root)` | Reads `sfdx-project.json`, returns default path string |
| 2 | `normalise_flow(path)` | Strip + sort XML; absorb from `normalise-flow.py` |
| 3 | `rewrite_flow_manifest(manifest_path, org, runner)` | Query active versions via Tooling API, rewrite XML; absorb from `ensure-active-flow-versions.py` |
| 4 | `normalise_apex(src, dest)` | Ensure trailing newline |
| 5 | `normalise_dashboard(src, dest)` | Strip `<owner>` / `<runningUser>` |
| 6 | `normalise_field(src, dest)` | Decode `&quot;` → `"` |
| 7 | `normalise_object(src, dest)` | Strip `<recordTypeTrackHistory>` |
| 8 | `generate_manifest(source_dir, output_path, runner)` | Assert correct `sf project generate manifest` args |
| 9 | `retrieve_metadata(manifest_path, org, tmp_dir, runner)` | Assert correct `sf project retrieve start` args |
| 10 | `run_diff(org_dir, local_dir, norm_dirs, file_path)` | Runs `diff`, returns output |
| 11 | `main(args)` | Smoke test with everything mocked |

## Tasks

- [ ] Add `pyproject.toml` at repo root with `[tool.pytest.ini_options]` pointing at `scripts/`
- [ ] Create `scripts/diff/tests/__init__.py`
- [ ] **TDD loop — for each unit 1–11:**
  - [ ] Write failing test(s)
  - [ ] Implement function in `diff_org_changes.py`
  - [ ] Green
- [ ] Add `__main__` entry point to `diff_org_changes.py` (calls `main(sys.argv)`)
- [ ] Delete `normalise-flow.py` and `ensure-active-flow-versions.py`
- [ ] Delete `diff-org-changes.sh`
- [ ] Update `CLAUDE.md` — scripts table and `/diff-org-changes` command
- [ ] Update `.cursor/skills/diff-org-changes/SKILL.md` — script path + invocation
- [ ] Run full test suite: `pytest scripts/`

## ADR

`docs/adr/0001-injectable-runner-for-subprocess.md` — injectable runner pattern

## Out of scope

- Live-org integration tests
- Changing normalisation logic (behaviour-preserving migration only)
- Parallelising normalisation across metadata types
