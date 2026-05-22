#!/usr/bin/env bash
# Compare org metadata with local source (for orgs without source tracking).
# Retrieves metadata from the org into a temp dir, then diffs against local src.
# Usage: diff-org-changes.sh [org-alias] [file-path]
#   org-alias: default home-denispoc
#   file-path: optional path for single-file diff (e.g. classes/cfp_getDataMovementsFromMetadata.cls)
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
TARGET_ORG="${1:-home-denispoc}"
FILE_PATH="${2:-}"
TMP_DIR="/tmp/sf-diff-org-retrieve-$$"

cleanup() {
  if [[ -z "${KEEP_DIFF_TMP:-}" ]]; then
    rm -rf "$TMP_DIR"
  fi
}
trap cleanup EXIT

cd "$REPO_ROOT"
mkdir -p "$TMP_DIR/main/default"

# sf project retrieve ignores --output-dir; it always writes to the default package dir.
# Work around this by running retrieve from inside a self-contained temp project whose
# default package dir is TMP_DIR itself.
TMP_PROJECT_DIR="$TMP_DIR/_project"
mkdir -p "$TMP_PROJECT_DIR"
cat > "$TMP_PROJECT_DIR/sfdx-project.json" <<EOF
{
  "packageDirectories": [{ "path": "retrieve-out", "default": true }],
  "sourceApiVersion": "66.0"
}
EOF
mkdir -p "$TMP_PROJECT_DIR/retrieve-out"

# Generate manifest from local source (covers all metadata in the project)
sf project generate manifest --source-dir "$REPO_ROOT/src" --name diff-package --output-dir "$TMP_DIR"

# Rewrite Flow members to use active version numbers (avoids retrieving wrong/draft version)
python3 "$SCRIPT_DIR/ensure-active-flow-versions.py" "$TMP_DIR/diff-package.xml" --org "$TARGET_ORG"

# Retrieve from org into the temp project (CLI writes to its default package dir)
cd "$TMP_PROJECT_DIR"
sf project retrieve start \
  --target-org "$TARGET_ORG" \
  --manifest "$TMP_DIR/diff-package.xml"
cd "$REPO_ROOT"

# Move retrieved files up to TMP_DIR for diffing (CLI writes to retrieve-out/main/default/)
rsync -a "$TMP_PROJECT_DIR/retrieve-out/main/default/" "$TMP_DIR/main/default/"
rm -rf "$TMP_PROJECT_DIR"

# Diff: retrieve puts files in TMP_DIR/{type}/, local uses src/main/default/{type}/
rm -f "$TMP_DIR/diff-package.xml"
echo "=== Normalisation (stripped before diff — not real differences) ==="
echo "  Flows        : locationX/locationY (canvas positions) | <status> (activation state) | element order"
echo "  Apex/Triggers: trailing newline (org omits, local adds)"
echo "  Dashboards   : <owner> | <runningUser> (runtime, user-specific)"
echo "  Fields       : &quot; → \" (XML entity vs literal — functionally identical)"
echo "  Objects      : <recordTypeTrackHistory> (platform-injected, absent from source)"
echo ""
echo "=== Differences (org vs local) ==="
echo "Left: org ($TARGET_ORG)  |  Right: local (src/main/default/)"
echo ""

ORG_RETRIEVE_DIR="$TMP_DIR/main/default"

# Normalise flow files before diffing:
#   - strips locationX/locationY (canvas positions, cosmetic)
#   - strips <status> (runtime activation state)
#   - sorts top-level named elements for stable ordering
ORG_FLOWS_NORM="$TMP_DIR/org-flows-norm"
LOCAL_FLOWS_NORM="$TMP_DIR/local-flows-norm"
mkdir -p "$ORG_FLOWS_NORM" "$LOCAL_FLOWS_NORM"

for f in "$ORG_RETRIEVE_DIR"/flows/*.flow-meta.xml; do
  [[ -f "$f" ]] && python3 "$SCRIPT_DIR/normalise-flow.py" "$f" > "$ORG_FLOWS_NORM/$(basename "$f")" 2>/dev/null
done
for f in src/main/default/flows/*.flow-meta.xml; do
  [[ -f "$f" ]] && python3 "$SCRIPT_DIR/normalise-flow.py" "$f" > "$LOCAL_FLOWS_NORM/$(basename "$f")" 2>/dev/null
done

# Normalise Apex files before diffing: org omits trailing newline, local has one.
# Copy both sides with a guaranteed trailing newline so EOF whitespace never shows as a diff.
ORG_APEX_NORM="$TMP_DIR/org-apex-norm"
LOCAL_APEX_NORM="$TMP_DIR/local-apex-norm"
mkdir -p "$ORG_APEX_NORM" "$LOCAL_APEX_NORM"

for f in "$ORG_RETRIEVE_DIR"/classes/*.cls "$ORG_RETRIEVE_DIR"/classes/*.cls-meta.xml \
         "$ORG_RETRIEVE_DIR"/triggers/*.trigger "$ORG_RETRIEVE_DIR"/triggers/*.trigger-meta.xml; do
  [[ -f "$f" ]] && { sed -e '$a\' "$f" > "$ORG_APEX_NORM/$(basename "$f")"; }
done
for f in src/main/default/classes/*.cls src/main/default/classes/*.cls-meta.xml \
         src/main/default/triggers/*.trigger src/main/default/triggers/*.trigger-meta.xml; do
  [[ -f "$f" ]] && { sed -e '$a\' "$f" > "$LOCAL_APEX_NORM/$(basename "$f")"; }
done

# Normalise dashboard files before diffing: strip <owner> and <runningUser> (user-specific, runtime-set)
ORG_DASH_NORM="$TMP_DIR/org-dash-norm"
LOCAL_DASH_NORM="$TMP_DIR/local-dash-norm"
mkdir -p "$ORG_DASH_NORM" "$LOCAL_DASH_NORM"

for f in "$ORG_RETRIEVE_DIR"/dashboards/**/*.dashboard-meta.xml; do
  [[ -f "$f" ]] && grep -v '<owner>' "$f" | grep -v '<runningUser>' > "$ORG_DASH_NORM/$(basename "$f")"
done
for f in src/main/default/dashboards/**/*.dashboard-meta.xml; do
  [[ -f "$f" ]] && grep -v '<owner>' "$f" | grep -v '<runningUser>' > "$LOCAL_DASH_NORM/$(basename "$f")"
done

# Normalise field XML before diffing: decode &quot; -> " (org serialises quotes as XML entity; local uses literals — functionally identical)
ORG_FIELD_NORM="$TMP_DIR/org-field-norm"
LOCAL_FIELD_NORM="$TMP_DIR/local-field-norm"
mkdir -p "$ORG_FIELD_NORM" "$LOCAL_FIELD_NORM"

while IFS= read -r -d '' f; do
  sed 's/&quot;/"/g' "$f" > "$ORG_FIELD_NORM/$(basename "$f")"
done < <(find "$ORG_RETRIEVE_DIR/objects" -name "*.field-meta.xml" -print0 2>/dev/null)
while IFS= read -r -d '' f; do
  sed 's/&quot;/"/g' "$f" > "$LOCAL_FIELD_NORM/$(basename "$f")"
done < <(find src/main/default/objects -name "*.field-meta.xml" -print0 2>/dev/null)

# Normalise object metadata before diffing: strip <recordTypeTrackHistory> (auto-injected by platform, not meaningful in source)
ORG_OBJ_NORM="$TMP_DIR/org-obj-norm"
LOCAL_OBJ_NORM="$TMP_DIR/local-obj-norm"
mkdir -p "$ORG_OBJ_NORM" "$LOCAL_OBJ_NORM"

while IFS= read -r -d '' f; do
  grep -v '<recordTypeTrackHistory>' "$f" > "$ORG_OBJ_NORM/$(basename "$f")"
done < <(find "$ORG_RETRIEVE_DIR/objects" -name "*.object-meta.xml" -print0 2>/dev/null)
while IFS= read -r -d '' f; do
  grep -v '<recordTypeTrackHistory>' "$f" > "$LOCAL_OBJ_NORM/$(basename "$f")"
done < <(find src/main/default/objects -name "*.object-meta.xml" -print0 2>/dev/null)

if [[ -n "$FILE_PATH" ]]; then
  REL_PATH="${FILE_PATH#src/main/default/}"
  ORG_FILE="$ORG_RETRIEVE_DIR/$REL_PATH"
  LOCAL_FILE="src/main/default/$REL_PATH"
  if [[ -f "$ORG_FILE" && -f "$LOCAL_FILE" ]]; then
    if [[ "$REL_PATH" == flows/* ]]; then
      FNAME="$(basename "$REL_PATH")"
      diff "$ORG_FLOWS_NORM/$FNAME" "$LOCAL_FLOWS_NORM/$FNAME" || true
    elif [[ "$REL_PATH" == classes/* || "$REL_PATH" == triggers/* ]]; then
      FNAME="$(basename "$REL_PATH")"
      diff "$ORG_APEX_NORM/$FNAME" "$LOCAL_APEX_NORM/$FNAME" || true
    elif [[ "$REL_PATH" == dashboards/* ]]; then
      FNAME="$(basename "$REL_PATH")"
      diff "$ORG_DASH_NORM/$FNAME" "$LOCAL_DASH_NORM/$FNAME" || true
    elif [[ "$REL_PATH" == objects/*.object-meta.xml || "$REL_PATH" == objects/*/*.object-meta.xml ]]; then
      FNAME="$(basename "$REL_PATH")"
      diff "$ORG_OBJ_NORM/$FNAME" "$LOCAL_OBJ_NORM/$FNAME" || true
    elif [[ "$REL_PATH" == objects/*/fields/*.field-meta.xml ]]; then
      FNAME="$(basename "$REL_PATH")"
      diff "$ORG_FIELD_NORM/$FNAME" "$LOCAL_FIELD_NORM/$FNAME" || true
    else
      diff "$ORG_FILE" "$LOCAL_FILE" || true
    fi
  else
    echo "File not found. Org: $ORG_FILE | Local: $LOCAL_FILE"
    exit 1
  fi
else
  diff -rq "$ORG_RETRIEVE_DIR" src/main/default \
    --exclude="*.flow-meta.xml" --exclude="*.cls" --exclude="*.cls-meta.xml" \
    --exclude="*.trigger" --exclude="*.trigger-meta.xml" \
    --exclude="*.dashboard-meta.xml" --exclude="*.object-meta.xml" \
    --exclude="*.field-meta.xml" --exclude=".DS_Store" \
    --exclude="jsconfig.json" --exclude="tsconfig.json" --exclude="tsconfig.*.json" || true
  diff -rq "$ORG_FLOWS_NORM" "$LOCAL_FLOWS_NORM" 2>/dev/null || true
  diff -rq "$ORG_APEX_NORM" "$LOCAL_APEX_NORM" 2>/dev/null || true
  diff -rq "$ORG_DASH_NORM" "$LOCAL_DASH_NORM" 2>/dev/null || true
  diff -rq "$ORG_OBJ_NORM" "$LOCAL_OBJ_NORM" 2>/dev/null || true
  diff -rq "$ORG_FIELD_NORM" "$LOCAL_FIELD_NORM" 2>/dev/null || true
fi
