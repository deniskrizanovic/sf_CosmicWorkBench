#!/usr/bin/env python3
"""
Rewrite Flow members in a package.xml manifest to use active version numbers.
Queries FlowDefinition via Tooling API to get ActiveVersion.VersionNumber for each flow.
"""
import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Optional


def get_active_version(flow_name: str, org: str) -> Optional[int]:
    """Query FlowDefinition for active version number."""
    query = (
        "SELECT ActiveVersion.VersionNumber FROM FlowDefinition "
        f"WHERE DeveloperName = '{flow_name}'"
    )
    result = subprocess.run(
        [
            "sf", "data", "query",
            "--query", query,
            "--target-org", org,
            "--use-tooling-api",
            "--json",
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        return None
    data = json.loads(result.stdout)
    records = data.get("result", {}).get("records", [])
    if not records:
        return None
    active = records[0].get("ActiveVersion")
    return active.get("VersionNumber") if active else None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("manifest", type=Path, help="Path to package.xml")
    parser.add_argument("--org", "-o", required=True, help="Target org alias")
    args = parser.parse_args()

    manifest_path = args.manifest
    if not manifest_path.exists():
        sys.exit(f"Manifest not found: {manifest_path}")

    content = manifest_path.read_text()

    # Find Flow type block and its members
    flow_members_match = re.search(
        r"<types>\s*((?:<members>[^<]+</members>\s*)*)\s*<name>Flow</name>\s*</types>",
        content,
        re.DOTALL,
    )
    if not flow_members_match:
        return 0  # No flows in manifest

    members_block = flow_members_match.group(1)
    flow_names = re.findall(r"<members>([^<]+)</members>", members_block)

    if not flow_names:
        return 0

    replacements = {}
    for name in flow_names:
        version = get_active_version(name, args.org)
        if version is not None:
            replacements[f"<members>{name}</members>"] = f"<members>{name}-{version}</members>"

    if not replacements:
        return 0

    for old, new in replacements.items():
        content = content.replace(old, new)

    manifest_path.write_text(content)
    return 0


if __name__ == "__main__":
    sys.exit(main())
