#!/usr/bin/env python3
"""
Prepare data CSVs for cross-org import: clear Id-based lookup columns
(keep columns, set values to empty) so SFDMU uses _r.cfp_External_Id__c for
lookup resolution. Set OwnerId to target org user (Name = 'Denis Krizanovic').
Replace #N/A with empty for restricted picklists (e.g. cfp_Early_And_Rapid_Estimation_Size__c).
Run before import script.
"""
import argparse
import csv
import json
import subprocess
from pathlib import Path

# Columns to clear (Id-based lookups - SFDMU will use _r.cfp_External_Id__c)
COLS_TO_CLEAR = {
    "cfp_FunctionalProcess__c.csv": ["cfp_System_Context__c"],
    "cfp_DataGroups__c.csv": ["cfp_System_Context__c"],
    "cfp_Data_Movements__c.csv": [
        "cfp_FunctionalProcess__c",
        "cfp_DataGroups__c",
        "cfp_Reused_from_Functional_Process__c",
        "cfp_Reused_Functional_Step__c",
    ],
}

COMMON_CLEAR = ["CreatedById", "LastModifiedById"]


def get_owner_id(target_org: str) -> str:
    """Get User Id where Name = 'Denis Krizanovic' from target org."""
    result = subprocess.run(
        [
            "sf",
            "data",
            "query",
            "-q",
            "SELECT Id FROM User WHERE Name = 'Denis Krizanovic' AND IsActive = true LIMIT 1",
            "-o",
            target_org,
            "--json",
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        raise SystemExit(f"Failed to query User: {result.stderr}")
    data = json.loads(result.stdout)
    records = data.get("result", {}).get("records", [])
    if not records:
        raise SystemExit("No User found with Name = 'Denis Krizanovic' in target org")
    return records[0]["Id"]


def main():
    parser = argparse.ArgumentParser(description="Prep CSVs for cross-org import")
    parser.add_argument(
        "-o",
        "--target-org",
        default="home-denispoc",
        help="Target org alias (default: home-denispoc)",
    )
    parser.add_argument(
        "-d",
        "--data-dir",
        default="HomesNSW_-_Maintenance_App",
        help="Data subdir under data/ (default: HomesNSW_-_Maintenance_App)",
    )
    args = parser.parse_args()

    owner_id = get_owner_id(args.target_org)
    print(f"  OwnerId set to {owner_id} (Denis Krizanovic)")

    script_dir = Path(__file__).resolve().parent
    data_dir = script_dir.parent / "data" / args.data_dir

    for filename, cols in COLS_TO_CLEAR.items():
        path = data_dir / filename
        if not path.exists():
            continue
        clear = set(cols) | set(COMMON_CLEAR)
        with open(path, newline="", encoding="utf-8-sig") as f:
            reader = csv.DictReader(f)
            rows = list(reader)
            fieldnames = list(reader.fieldnames)
        if "OwnerId" not in fieldnames:
            fieldnames.append("OwnerId")
        for row in rows:
            for c in clear:
                if c in row:
                    row[c] = ""
            for k in row:
                if row[k] == "#N/A":
                    row[k] = ""
            row["OwnerId"] = owner_id
        with open(path, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
            writer.writeheader()
            writer.writerows(rows)
        print(f"  {filename}: cleared {clear}, #N/A->empty, OwnerId={owner_id}")

    sc_path = data_dir / "cfp_System_Context__c.csv"
    if sc_path.exists():
        with open(sc_path, newline="", encoding="utf-8-sig") as f:
            reader = csv.DictReader(f)
            rows = list(reader)
            fieldnames = list(reader.fieldnames)
        if "OwnerId" not in fieldnames:
            fieldnames.append("OwnerId")
        for row in rows:
            for c in COMMON_CLEAR:
                if c in row:
                    row[c] = ""
            for k in row:
                if row[k] == "#N/A":
                    row[k] = ""
            row["OwnerId"] = owner_id
        with open(sc_path, "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
            writer.writeheader()
            writer.writerows(rows)
        print(f"  cfp_System_Context__c.csv: cleared {COMMON_CLEAR}, #N/A->empty, OwnerId={owner_id}")

    print(f"Prep complete. Run import script for {args.data_dir}")


if __name__ == "__main__":
    main()
