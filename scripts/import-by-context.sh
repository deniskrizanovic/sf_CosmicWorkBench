#!/usr/bin/env bash
# Import data from a system-context data directory into target org (debug-friendly).
# Reusable for any data subdir: HomesNSW_-_Maintenance_App, Salesforce_Platform_Features, etc.
#
# Usage:
#   ./scripts/import-by-context.sh <DATA_SUBDIR>              # Import all objects
#   OBJECT=cfp_System_Context__c ./scripts/import-by-context.sh <DATA_SUBDIR>
#   SLOW=1 ./scripts/import-by-context.sh <DATA_SUBDIR>         # Pause before each object
#   TARGET_ORG=my-org ./scripts/import-by-context.sh <DATA_SUBDIR>
#   KEEP_TMP=1 ./scripts/import-by-context.sh <DATA_SUBDIR>    # Keep temp dir for debugging
#   DIAGNOSTIC=1 ./scripts/import-by-context.sh <DATA_SUBDIR>
#
# Examples:
#   ./scripts/import-by-context.sh HomesNSW_-_Maintenance_App
#   ./scripts/import-by-context.sh Salesforce_Platform_Features
#   OBJECT=cfp_FunctionalProcess__c ./scripts/import-by-context.sh Salesforce_Platform_Features
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_ORG="${TARGET_ORG:-home-denispoc}"

# DATA_SUBDIR: first arg, or env var, or default
DATA_SUBDIR="${1:-${DATA_SUBDIR:-}}"
if [[ -z "$DATA_SUBDIR" ]]; then
  echo "Usage: $0 <DATA_SUBDIR>"
  echo "  e.g. $0 HomesNSW_-_Maintenance_App"
  echo "  e.g. $0 Salesforce_Platform_Features"
  echo ""
  echo "Data dirs: $(ls -1 "$REPO_ROOT/data" 2>/dev/null | grep -v '^_all$' | grep -v README | tr '\n' ' ')"
  exit 1
fi

DATA_DIR="$REPO_ROOT/data/$DATA_SUBDIR"
if [[ ! -f "$DATA_DIR/export.json" ]]; then
  echo "Error: $DATA_DIR/export.json not found."
  exit 1
fi

# Clear stale source/target from prior runs
rm -rf "$DATA_DIR/source" "$DATA_DIR/target"

# Prep CSVs for cross-org import
python3 "$SCRIPT_DIR/prep-for-import.py" -o "$TARGET_ORG" -d "$DATA_SUBDIR"
echo ""

if [[ -n "$OBJECT" ]]; then
  # For Data Movements: prep clears lookups; resolve must run after prep to populate from target
  if [[ "$OBJECT" == "cfp_Data_Movements__c" ]]; then
    echo "Resolving Data Movements lookups from target org..."
    python3 "$SCRIPT_DIR/resolve-dm-lookups.py" -o "$TARGET_ORG" -d "$DATA_SUBDIR"
    echo ""
  fi
  # Single-object mode: use isolated temp dir to avoid stale source/ from other contexts
  TMP_DIR=$(mktemp -d)
  trap 'rm -rf "$TMP_DIR"' EXIT
  if ! jq -e --arg obj "$OBJECT" '.objects | [.[] | select(.query | test("FROM " + $obj + "\\b"; "i"))] | length > 0' "$DATA_DIR/export.json" > /dev/null 2>&1; then
    echo "Error: Object '$OBJECT' not found in export.json"
    exit 1
  fi
  jq --arg obj "$OBJECT" '.objects |= [.[] | select(.query | test("FROM " + $obj + "\\b"; "i"))]' "$DATA_DIR/export.json" > "$TMP_DIR/export.json"
  OBJECT_CSV="${OBJECT}.csv"
  if [[ -f "$DATA_DIR/$OBJECT_CSV" ]]; then
    cp "$DATA_DIR/$OBJECT_CSV" "$TMP_DIR/"
  else
    echo "Error: $DATA_DIR/$OBJECT_CSV not found"
    exit 1
  fi
  ROW_COUNT=$(($(wc -l < "$TMP_DIR/$OBJECT_CSV") - 1))
  echo "Importing $OBJECT ($ROW_COUNT records) from $DATA_SUBDIR to $TARGET_ORG"
  SFDMU_OPTS=(--noprompt)
  [[ -n "$DIAGNOSTIC" ]] && SFDMU_OPTS+=(--diagnostic)
  (cd "$TMP_DIR" && sf sfdmu run --sourceusername csvfile --targetusername "$TARGET_ORG" -p . "${SFDMU_OPTS[@]}")
  [[ -n "$KEEP_TMP" ]] && echo "Temp dir kept: $TMP_DIR" && trap - EXIT
  echo "Import complete."
  exit 0
fi

if [[ -n "$SLOW" ]]; then
  OBJECTS=$(jq -r '.objects[].query | match("FROM ([a-zA-Z0-9_]+)") | .captures[0].string' "$DATA_DIR/export.json")
  for obj in $OBJECTS; do
    [[ -f "$DATA_DIR/${obj}.csv" ]] || continue
    echo "--- Importing $obj ---"
    OBJECT="$obj" "$0" "$DATA_SUBDIR"
    echo ""
    read -p "Press Enter to continue (or Ctrl+C to stop)..."
  done
  echo "All objects imported."
else
  # Two-phase import: SFDMU does not resolve lookups from external-ID columns when source is CSV.
  # Phase 1: Import parents (SC, FP, DG). Phase 2: Resolve DM lookups, then import DM.
  PARENT_OBJECTS="cfp_System_Context__c cfp_FunctionalProcess__c cfp_DataGroups__c"
  DM_OBJECT="cfp_Data_Movements__c"
  if [[ -f "$DATA_DIR/$DM_OBJECT.csv" ]]; then
    echo "Phase 1: Importing parents (SC, FP, DG) to $TARGET_ORG"
    for obj in $PARENT_OBJECTS; do
      [[ -f "$DATA_DIR/${obj}.csv" ]] || continue
      OBJECT="$obj" "$0" "$DATA_SUBDIR"
    done
    echo ""
    echo "Resolving Data Movements lookups from target org..."
    python3 "$SCRIPT_DIR/resolve-dm-lookups.py" -o "$TARGET_ORG" -d "$DATA_SUBDIR"
    echo ""
    echo "Phase 2: Importing $DM_OBJECT"
    OBJECT="$DM_OBJECT" "$0" "$DATA_SUBDIR"
  else
    echo "Importing from $DATA_DIR to $TARGET_ORG"
    sf sfdmu run --sourceusername csvfile --targetusername "$TARGET_ORG" -p "$DATA_DIR" --noprompt
  fi
  echo "Import complete."
fi
