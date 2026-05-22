# SFDMU Data

- `_all/` — Full export (all records). Use for import to home-denispoc.
- `{SystemContextName}/` — Per–System Context subsets (created by `scripts/data/split-by-system-context.py`).

## Usage

1. Export: `./scripts/data/export-data.sh`
2. Split: `python3 scripts/data/split-by-system-context.py`
3. Import: `./scripts/data/import-data.sh`
