# SFDMU Data

- `_all/` — Full export (all records). Use for import to home-denispoc.
- `{SystemContextName}/` — Per–System Context subsets (created by `scripts/split-by-system-context.py`).

## Usage

1. Export: `./scripts/export-data.sh`
2. Split: `python3 scripts/split-by-system-context.py`
3. Import: `./scripts/import-data.sh`
