#!/usr/bin/env python3
"""
Split data/_all CSVs into per-System-Context subdirectories.
Run after scripts/export-data.sh.
"""
import csv
import re
import shutil
from pathlib import Path


def sanitize_name(name: str) -> str:
    """Sanitize System Context Name for use as directory name."""
    s = re.sub(r'[^\w\s-]', '', name)
    s = re.sub(r'[\s_]+', '_', s).strip('_')
    return s or "unnamed"


def main():
    script_dir = Path(__file__).resolve().parent
    repo_root = script_dir.parent
    all_dir = repo_root / "data" / "_all"

    if not (all_dir / "cfp_System_Context__c.csv").exists():
        print(f"Error: {all_dir}/cfp_System_Context__c.csv not found. Run scripts/export-data.sh first.")
        raise SystemExit(1)

    # Load System Contexts (utf-8-sig strips BOM if present)
    sc_rows = []
    with open(all_dir / "cfp_System_Context__c.csv", newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        sc_rows = list(reader)

    # Load FunctionalProcess
    fp_rows = []
    with open(all_dir / "cfp_FunctionalProcess__c.csv", newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        fp_rows = list(reader)

    # Load DataGroups
    dg_rows = []
    with open(all_dir / "cfp_DataGroups__c.csv", newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        dg_rows = list(reader)

    # Load Data_Movements
    dm_rows = []
    with open(all_dir / "cfp_Data_Movements__c.csv", newline="", encoding="utf-8-sig") as f:
        reader = csv.DictReader(f)
        dm_rows = list(reader)

    # Create per-SC directories
    for sc_row in sc_rows:
        sc_id = sc_row.get("Id", "").strip()
        sc_name = sc_row.get("Name", "").strip()
        dir_name = sanitize_name(sc_name)
        out_dir = repo_root / "data" / dir_name
        out_dir.mkdir(parents=True, exist_ok=True)

        # SC: single row
        with open(out_dir / "cfp_System_Context__c.csv", "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=sc_row.keys(), extrasaction="ignore")
            writer.writeheader()
            writer.writerow(sc_row)

        # FP: filter by cfp_System_Context__c (Id)
        fp_subset = [r for r in fp_rows if r.get("cfp_System_Context__c", "").strip() == sc_id]
        if fp_subset:
            with open(out_dir / "cfp_FunctionalProcess__c.csv", "w", newline="", encoding="utf-8") as f:
                writer = csv.DictWriter(f, fieldnames=fp_subset[0].keys(), extrasaction="ignore")
                writer.writeheader()
                writer.writerows(fp_subset)

        # DG: filter by cfp_System_Context__c (Id)
        dg_subset = [r for r in dg_rows if r.get("cfp_System_Context__c", "").strip() == sc_id]
        if dg_subset:
            with open(out_dir / "cfp_DataGroups__c.csv", "w", newline="", encoding="utf-8") as f:
                writer = csv.DictWriter(f, fieldnames=dg_subset[0].keys(), extrasaction="ignore")
                writer.writeheader()
                writer.writerows(dg_subset)

        # DM: filter by cfp_FunctionalProcess__c in this SC's FPs
        fp_ids = {r.get("Id", "").strip() for r in fp_subset}
        dm_subset = [r for r in dm_rows if r.get("cfp_FunctionalProcess__c", "").strip() in fp_ids]
        if dm_subset:
            with open(out_dir / "cfp_Data_Movements__c.csv", "w", newline="", encoding="utf-8") as f:
                writer = csv.DictWriter(f, fieldnames=dm_subset[0].keys(), extrasaction="ignore")
                writer.writeheader()
                writer.writerows(dm_subset)

        # Copy export.json
        shutil.copy(all_dir / "export.json", out_dir / "export.json")

        print(f"  {dir_name}: SC=1, FP={len(fp_subset)}, DG={len(dg_subset)}, DM={len(dm_subset)}")

    print(f"Split complete. Created {len(sc_rows)} subdirectories under data/.")


if __name__ == "__main__":
    main()
