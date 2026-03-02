#!/usr/bin/env bash
# Import data from data/_all into home-denispoc using SFDMU
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
DATA_DIR="$REPO_ROOT/data/_all"

if [[ ! -f "$DATA_DIR/export.json" ]]; then
  echo "Error: $DATA_DIR/export.json not found. Run scripts/export-data.sh first."
  exit 1
fi

# Run prep-for-import.py first to clear Id-based lookups and set OwnerId (required for cross-org)
python3 "$SCRIPT_DIR/prep-for-import.py" -o home-denispoc
echo "Importing from $DATA_DIR to home-denispoc"
sf sfdmu run --sourceusername csvfile --targetusername home-denispoc -p "$DATA_DIR"
echo "Import complete."
