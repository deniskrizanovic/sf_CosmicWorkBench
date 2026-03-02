#!/usr/bin/env bash
# Export data from au-pss-ido-cfp to data/_all using SFDMU
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="$REPO_ROOT/data/_all"

echo "Exporting from au-pss-ido-cfp to $DATA_DIR"
sf sfdmu run --sourceusername au-pss-ido-cfp --targetusername csvfile -p "$DATA_DIR"
echo "Export complete. Run scripts/split-by-system-context.py to create per-SC subdirs."
