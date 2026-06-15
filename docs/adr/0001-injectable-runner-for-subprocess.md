# Injectable runner for subprocess calls

All functions in `diff_org_changes.py` that shell out to the `sf` CLI accept a `runner` parameter (default: `subprocess.run`). Tests pass a fake callable instead of monkeypatching the global.

The alternative — `monkeypatch` on `subprocess.run` — couples tests to the internal import path of the module and requires pytest magic to intercept. An explicit parameter makes the seam visible in the function signature, keeps tests readable without fixture setup, and documents that every shell-out is an injectable boundary.

## Considered Options

- **monkeypatch on `subprocess.run`** — rejected because it hides the test seam and couples tests to module internals
- **Pre-recorded fixtures (replay from JSON)** — rejected because `sf` CLI output format changes would silently break tests
