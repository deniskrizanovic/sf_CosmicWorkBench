#!/usr/bin/env bash
# Compare org metadata with local source (for orgs without source tracking).
# Retrieves metadata from the org into a temp dir, then diffs against local src.
# Usage: diff-org-changes.sh [org-alias] [file-path]
#   org-alias: default home-denispoc
#   file-path: optional path for single-file diff (e.g. classes/cfp_getDataMovementsFromMetadata.cls)
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_ORG="${1:-home-denispoc}"
FILE_PATH="${2:-}"
TMP_DIR="$REPO_ROOT/.tmp-org-retrieve"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

cd "$REPO_ROOT"
mkdir -p "$TMP_DIR"

# Generate manifest from local source (covers all metadata in the project)
sf project generate manifest --source-dir src --name diff-package --output-dir "$TMP_DIR"

# Retrieve from org (output must be inside project)
sf project retrieve start \
  --target-org "$TARGET_ORG" \
  --manifest "$TMP_DIR/diff-package.xml" \
  --output-dir "$TMP_DIR"

# Diff: retrieve puts files in TMP_DIR/{type}/, local uses src/main/default/{type}/
rm -f "$TMP_DIR/diff-package.xml"
echo "=== Differences (org vs local) ==="
echo "Left: org ($TARGET_ORG)  |  Right: local (src/main/default/)"
echo ""

if [[ -n "$FILE_PATH" ]]; then
  # Normalize: strip src/main/default/ prefix if present
  REL_PATH="${FILE_PATH#src/main/default/}"
  ORG_FILE="$TMP_DIR/$REL_PATH"
  LOCAL_FILE="src/main/default/$REL_PATH"
  if [[ -f "$ORG_FILE" && -f "$LOCAL_FILE" ]]; then
    diff "$ORG_FILE" "$LOCAL_FILE" || true
  else
    echo "File not found. Org: $ORG_FILE | Local: $LOCAL_FILE"
    exit 1
  fi
else
  diff -rq "$TMP_DIR" src/main/default || true
fi
