#!/usr/bin/env python3
"""
Compare org metadata with local source (for orgs without source tracking).
Retrieves metadata from the org into a temp dir, then diffs against local src.

Migrated from diff-org-changes.sh — behaviour-preserving.
"""
import argparse
import glob
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from xml.etree import ElementTree as ET


# ---------------------------------------------------------------------------
# Flow normalisation constants (absorbed from normalise-flow.py)
# ---------------------------------------------------------------------------

STRIP_TAGS = {"locationX", "locationY", "status", "styleProperties"}

SORTABLE_TAGS = {
    "actionCalls", "assignments", "choices", "collectionProcessors",
    "constants", "customErrors", "decisions", "dynamicChoiceSets",
    "loops", "orchestratedStages", "recordCreates", "recordDeletes",
    "recordLookups", "recordUpdates", "screens", "subflows",
    "transforms", "variables", "waits",
}

NS = "http://soap.sforce.com/2006/04/metadata"


# ---------------------------------------------------------------------------
# detect_package_dir
# ---------------------------------------------------------------------------

def detect_package_dir(project_root):
    """Read sfdx-project.json, return default package path (trailing slash stripped). Default 'src'."""
    try:
        with open(os.path.join(project_root, "sfdx-project.json")) as f:
            data = json.load(f)
        dirs = data.get("packageDirectories", [])
        default = next((d for d in dirs if d.get("default")), dirs[0] if dirs else None)
        return default["path"].rstrip("/") if default else "src"
    except Exception:
        return "src"


# ---------------------------------------------------------------------------
# normalise_flow
# ---------------------------------------------------------------------------

def _local_tag(tag):
    return tag.replace(f"{{{NS}}}", "")


def _element_sort_key(el):
    name_el = el.find(f"{{{NS}}}name")
    name = name_el.text if name_el is not None else ""
    return (_local_tag(el.tag), name)


def _strip_and_sort(el):
    to_remove = [c for c in list(el) if _local_tag(c.tag) in STRIP_TAGS]
    for child in to_remove:
        el.remove(child)

    for child in list(el):
        _strip_and_sort(child)

    sortable = [c for c in list(el) if _local_tag(c.tag) in SORTABLE_TAGS]
    if sortable:
        non_sortable = [c for c in list(el) if _local_tag(c.tag) not in SORTABLE_TAGS]
        el[:] = non_sortable + sorted(sortable, key=_element_sort_key)


def normalise_flow(path):
    """Normalise a Flow XML file: strip cosmetic tags, sort elements. Returns XML string."""
    ET.register_namespace("", NS)
    tree = ET.parse(path)
    root = tree.getroot()
    _strip_and_sort(root)
    ET.indent(tree, space="    ")
    return ET.tostring(root, encoding="unicode")


# ---------------------------------------------------------------------------
# rewrite_flow_manifest (absorbed from ensure-active-flow-versions.py)
# ---------------------------------------------------------------------------

def _get_active_version(flow_name, org, runner=subprocess.run):
    query = (
        "SELECT ActiveVersion.VersionNumber FROM FlowDefinition "
        f"WHERE DeveloperName = '{flow_name}'"
    )
    result = runner(
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


def rewrite_flow_manifest(manifest_path, org, runner=subprocess.run):
    """Rewrite Flow members in package.xml to use active version numbers."""
    path = Path(manifest_path)
    content = path.read_text()

    flow_members_match = re.search(
        r"<types>\s*((?:<members>[^<]+</members>\s*)*)\s*<name>Flow</name>\s*</types>",
        content,
        re.DOTALL,
    )
    if not flow_members_match:
        return

    members_block = flow_members_match.group(1)
    flow_names = re.findall(r"<members>([^<]+)</members>", members_block)

    if not flow_names:
        return

    replacements = {}
    for name in flow_names:
        version = _get_active_version(name, org, runner=runner)
        if version is not None:
            replacements[f"<members>{name}</members>"] = f"<members>{name}-{version}</members>"

    if not replacements:
        return

    for old, new in replacements.items():
        content = content.replace(old, new)

    path.write_text(content)


# ---------------------------------------------------------------------------
# normalise_apex
# ---------------------------------------------------------------------------

def normalise_apex(src, dest):
    """Copy src to dest, ensuring trailing newline."""
    content = Path(src).read_text()
    if not content.endswith("\n"):
        content += "\n"
    Path(dest).write_text(content)


# ---------------------------------------------------------------------------
# normalise_dashboard
# ---------------------------------------------------------------------------

def normalise_dashboard(src, dest):
    """Copy src to dest, stripping lines containing <owner> or <runningUser>."""
    lines = Path(src).read_text().splitlines(keepends=True)
    filtered = [l for l in lines if "<owner>" not in l and "<runningUser>" not in l]
    Path(dest).write_text("".join(filtered))


# ---------------------------------------------------------------------------
# normalise_field
# ---------------------------------------------------------------------------

def normalise_field(src, dest):
    """Copy src to dest, replacing &quot; with literal double-quote."""
    content = Path(src).read_text()
    content = content.replace("&quot;", '"')
    Path(dest).write_text(content)


# ---------------------------------------------------------------------------
# normalise_validation_rule
# ---------------------------------------------------------------------------

def normalise_validation_rule(src, dest):
    """Copy src to dest, converting CDATA sections to XML entity encoding for consistent comparison."""
    content = Path(src).read_text()
    content = re.sub(
        r'<!\[CDATA\[(.*?)\]\]>',
        lambda m: m.group(1).replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;'),
        content,
        flags=re.DOTALL,
    )
    Path(dest).write_text(content)


# ---------------------------------------------------------------------------
# normalise_object
# ---------------------------------------------------------------------------

def normalise_object(src, dest):
    """Copy src to dest, stripping lines containing <recordTypeTrackHistory>."""
    lines = Path(src).read_text().splitlines(keepends=True)
    filtered = [l for l in lines if "<recordTypeTrackHistory>" not in l]
    Path(dest).write_text("".join(filtered))


# ---------------------------------------------------------------------------
# generate_manifest
# ---------------------------------------------------------------------------

def generate_manifest(source_dir, output_path, runner=subprocess.run):
    """Run sf project generate manifest for the given source directory."""
    output_dir = str(Path(output_path).parent)
    runner(
        [
            "sf", "project", "generate", "manifest",
            "--source-dir", source_dir,
            "--name", "diff-package",
            "--output-dir", output_dir,
        ],
        capture_output=True,
        text=True,
    )


# ---------------------------------------------------------------------------
# retrieve_metadata
# ---------------------------------------------------------------------------

def retrieve_metadata(manifest_path, org, tmp_project_dir, runner=subprocess.run):
    """Run sf project retrieve start with cwd set to tmp_project_dir."""
    runner(
        [
            "sf", "project", "retrieve", "start",
            "--target-org", org,
            "--manifest", manifest_path,
        ],
        capture_output=True,
        text=True,
        cwd=tmp_project_dir,
    )


# ---------------------------------------------------------------------------
# run_diff
# ---------------------------------------------------------------------------

def run_diff(org_dir, local_dir, norm_dirs, file_path=""):
    """Run diff commands matching the shell script logic. Returns combined output string."""
    output_parts = []

    if file_path:
        # Single-file diff
        rel_path = file_path
        org_file = os.path.join(org_dir, rel_path)
        local_file = os.path.join(local_dir, rel_path)

        if not os.path.isfile(org_file) or not os.path.isfile(local_file):
            return f"File not found. Org: {org_file} | Local: {local_file}"

        fname = os.path.basename(rel_path)

        if rel_path.startswith("flows/"):
            left = os.path.join(norm_dirs["flows_org"], fname)
            right = os.path.join(norm_dirs["flows_local"], fname)
        elif rel_path.startswith("classes/") or rel_path.startswith("triggers/"):
            left = os.path.join(norm_dirs["apex_org"], fname)
            right = os.path.join(norm_dirs["apex_local"], fname)
        elif rel_path.startswith("dashboards/"):
            left = os.path.join(norm_dirs["dash_org"], fname)
            right = os.path.join(norm_dirs["dash_local"], fname)
        elif rel_path.endswith(".object-meta.xml"):
            left = os.path.join(norm_dirs["obj_org"], fname)
            right = os.path.join(norm_dirs["obj_local"], fname)
        elif rel_path.endswith(".field-meta.xml"):
            left = os.path.join(norm_dirs["field_org"], fname)
            right = os.path.join(norm_dirs["field_local"], fname)
        elif rel_path.endswith(".validationRule-meta.xml"):
            left = os.path.join(norm_dirs["vr_org"], fname)
            right = os.path.join(norm_dirs["vr_local"], fname)
        else:
            left = org_file
            right = local_file

        result = subprocess.run(["diff", left, right], capture_output=True, text=True)
        output_parts.append(result.stdout)
    else:
        # Full diff: compare all metadata types
        excludes = [
            "--exclude=*.flow-meta.xml",
            "--exclude=*.cls", "--exclude=*.cls-meta.xml",
            "--exclude=*.trigger", "--exclude=*.trigger-meta.xml",
            "--exclude=*.dashboard-meta.xml",
            "--exclude=*.object-meta.xml",
            "--exclude=*.field-meta.xml",
            "--exclude=*.validationRule-meta.xml",
            "--exclude=.DS_Store",
            "--exclude=jsconfig.json",
            "--exclude=tsconfig.json",
            "--exclude=tsconfig.*.json",
        ]
        result = subprocess.run(
            ["diff", "-rq", org_dir, local_dir] + excludes,
            capture_output=True, text=True,
        )
        output_parts.append(result.stdout)

        # Normalised diffs
        for key_prefix in ["flows", "apex", "dash", "obj", "field", "vr"]:
            org_norm = norm_dirs[f"{key_prefix}_org"]
            local_norm = norm_dirs[f"{key_prefix}_local"]
            if os.path.isdir(org_norm) and os.path.isdir(local_norm):
                result = subprocess.run(
                    ["diff", "-rq", org_norm, local_norm],
                    capture_output=True, text=True,
                )
                output_parts.append(result.stdout)

    return "".join(output_parts)


# ---------------------------------------------------------------------------
# main
# ---------------------------------------------------------------------------

def main(args=None):
    """Orchestrate the full org diff workflow."""
    parser = argparse.ArgumentParser(description="Compare org metadata with local source.")
    parser.add_argument("--org", default="home-denispoc", help="Target org alias")
    parser.add_argument("--file", dest="file_path", default="", help="Optional single-file path (relative to main/default/)")
    parsed = parser.parse_args(args)

    repo_root = os.getcwd()
    pkg_dir = detect_package_dir(repo_root)
    local_src = os.path.join(repo_root, pkg_dir, "main", "default")

    # Create temp directory
    tmp_dir = tempfile.mkdtemp(prefix="sf-diff-org-retrieve-")
    try:
        os.makedirs(os.path.join(tmp_dir, "main", "default"), exist_ok=True)

        # Create temp project for sf retrieve
        tmp_project_dir = os.path.join(tmp_dir, "_project")
        os.makedirs(tmp_project_dir)
        sfdx_proj = {
            "packageDirectories": [{"path": "retrieve-out", "default": True}],
            "sourceApiVersion": "66.0",
        }
        with open(os.path.join(tmp_project_dir, "sfdx-project.json"), "w") as f:
            json.dump(sfdx_proj, f)
        os.makedirs(os.path.join(tmp_project_dir, "retrieve-out"))

        # Generate manifest
        manifest_path = os.path.join(tmp_dir, "diff-package.xml")
        source_dir = os.path.join(repo_root, pkg_dir)
        generate_manifest(source_dir, manifest_path)

        # Rewrite flow members to active versions
        rewrite_flow_manifest(manifest_path, parsed.org)

        # Retrieve from org
        retrieve_metadata(manifest_path, parsed.org, tmp_project_dir)

        # Move retrieved files to tmp_dir for diffing
        retrieve_out = os.path.join(tmp_project_dir, "retrieve-out", "main", "default")
        org_retrieve_dir = os.path.join(tmp_dir, "main", "default")
        if os.path.isdir(retrieve_out):
            # rsync equivalent: copy tree contents
            for item in os.listdir(retrieve_out):
                s = os.path.join(retrieve_out, item)
                d = os.path.join(org_retrieve_dir, item)
                if os.path.isdir(s):
                    shutil.copytree(s, d, dirs_exist_ok=True)
                else:
                    shutil.copy2(s, d)
        shutil.rmtree(tmp_project_dir)

        # Remove manifest from diff area
        if os.path.exists(manifest_path):
            os.remove(manifest_path)

        # Print normalisation header
        print("")
        print("=" * 72)
        print("  Normalisation (stripped before diff -- not real differences)")
        print("=" * 72)
        print("  Flows            : locationX/locationY (canvas positions) | <status> (activation state) | element order")
        print("  Apex/Triggers    : trailing newline (org omits, local adds)")
        print("  Dashboards       : <owner> | <runningUser> (runtime, user-specific)")
        print("  Fields           : &quot; -> \" (XML entity vs literal -- functionally identical)")
        print("  Objects          : <recordTypeTrackHistory> (platform-injected, absent from source)")
        print("  Validation Rules : <![CDATA[...]]> -> &lt;&gt; (CDATA vs XML entity -- functionally identical)")
        print("=" * 72)
        print("")
        print("=" * 72)
        print(f"  Differences (org vs local)")
        print(f"  Left: org ({parsed.org})  |  Right: local ({local_src}/)")
        print("=" * 72)
        print("")

        # Normalise flows
        flows_org_norm = os.path.join(tmp_dir, "org-flows-norm")
        flows_local_norm = os.path.join(tmp_dir, "local-flows-norm")
        os.makedirs(flows_org_norm, exist_ok=True)
        os.makedirs(flows_local_norm, exist_ok=True)

        org_flows_dir = os.path.join(org_retrieve_dir, "flows")
        local_flows_dir = os.path.join(local_src, "flows")

        if os.path.isdir(org_flows_dir):
            for f in glob.glob(os.path.join(org_flows_dir, "*.flow-meta.xml")):
                try:
                    result = normalise_flow(f)
                    Path(os.path.join(flows_org_norm, os.path.basename(f))).write_text(result)
                except Exception:
                    pass
        if os.path.isdir(local_flows_dir):
            for f in glob.glob(os.path.join(local_flows_dir, "*.flow-meta.xml")):
                try:
                    result = normalise_flow(f)
                    Path(os.path.join(flows_local_norm, os.path.basename(f))).write_text(result)
                except Exception:
                    pass

        # Normalise apex
        apex_org_norm = os.path.join(tmp_dir, "org-apex-norm")
        apex_local_norm = os.path.join(tmp_dir, "local-apex-norm")
        os.makedirs(apex_org_norm, exist_ok=True)
        os.makedirs(apex_local_norm, exist_ok=True)

        for subdir in ["classes", "triggers"]:
            org_subdir = os.path.join(org_retrieve_dir, subdir)
            local_subdir = os.path.join(local_src, subdir)
            if os.path.isdir(org_subdir):
                for f in os.listdir(org_subdir):
                    fpath = os.path.join(org_subdir, f)
                    if os.path.isfile(fpath):
                        normalise_apex(fpath, os.path.join(apex_org_norm, f))
            if os.path.isdir(local_subdir):
                for f in os.listdir(local_subdir):
                    fpath = os.path.join(local_subdir, f)
                    if os.path.isfile(fpath):
                        normalise_apex(fpath, os.path.join(apex_local_norm, f))

        # Normalise dashboards
        dash_org_norm = os.path.join(tmp_dir, "org-dash-norm")
        dash_local_norm = os.path.join(tmp_dir, "local-dash-norm")
        os.makedirs(dash_org_norm, exist_ok=True)
        os.makedirs(dash_local_norm, exist_ok=True)

        for base_dir, norm_dir in [(org_retrieve_dir, dash_org_norm), (local_src, dash_local_norm)]:
            dash_dir = os.path.join(base_dir, "dashboards")
            if os.path.isdir(dash_dir):
                for f in glob.glob(os.path.join(dash_dir, "**", "*.dashboard-meta.xml"), recursive=True):
                    normalise_dashboard(f, os.path.join(norm_dir, os.path.basename(f)))

        # Normalise fields
        field_org_norm = os.path.join(tmp_dir, "org-field-norm")
        field_local_norm = os.path.join(tmp_dir, "local-field-norm")
        os.makedirs(field_org_norm, exist_ok=True)
        os.makedirs(field_local_norm, exist_ok=True)

        for base_dir, norm_dir in [(org_retrieve_dir, field_org_norm), (local_src, field_local_norm)]:
            objects_dir = os.path.join(base_dir, "objects")
            if os.path.isdir(objects_dir):
                for f in glob.glob(os.path.join(objects_dir, "**", "*.field-meta.xml"), recursive=True):
                    normalise_field(f, os.path.join(norm_dir, os.path.basename(f)))

        # Normalise objects
        obj_org_norm = os.path.join(tmp_dir, "org-obj-norm")
        obj_local_norm = os.path.join(tmp_dir, "local-obj-norm")
        os.makedirs(obj_org_norm, exist_ok=True)
        os.makedirs(obj_local_norm, exist_ok=True)

        for base_dir, norm_dir in [(org_retrieve_dir, obj_org_norm), (local_src, obj_local_norm)]:
            objects_dir = os.path.join(base_dir, "objects")
            if os.path.isdir(objects_dir):
                for f in glob.glob(os.path.join(objects_dir, "**", "*.object-meta.xml"), recursive=True):
                    normalise_object(f, os.path.join(norm_dir, os.path.basename(f)))

        # Normalise validation rules
        vr_org_norm = os.path.join(tmp_dir, "org-vr-norm")
        vr_local_norm = os.path.join(tmp_dir, "local-vr-norm")
        os.makedirs(vr_org_norm, exist_ok=True)
        os.makedirs(vr_local_norm, exist_ok=True)

        for base_dir, norm_dir in [(org_retrieve_dir, vr_org_norm), (local_src, vr_local_norm)]:
            objects_dir = os.path.join(base_dir, "objects")
            if os.path.isdir(objects_dir):
                for f in glob.glob(os.path.join(objects_dir, "**", "*.validationRule-meta.xml"), recursive=True):
                    normalise_validation_rule(f, os.path.join(norm_dir, os.path.basename(f)))

        # Run diff
        norm_dirs = {
            "flows_org": flows_org_norm,
            "flows_local": flows_local_norm,
            "apex_org": apex_org_norm,
            "apex_local": apex_local_norm,
            "dash_org": dash_org_norm,
            "dash_local": dash_local_norm,
            "field_org": field_org_norm,
            "field_local": field_local_norm,
            "obj_org": obj_org_norm,
            "obj_local": obj_local_norm,
            "vr_org": vr_org_norm,
            "vr_local": vr_local_norm,
        }

        output = run_diff(org_retrieve_dir, local_src, norm_dirs, file_path=parsed.file_path)
        if output:
            print(output)

    finally:
        if not os.environ.get("KEEP_DIFF_TMP"):
            shutil.rmtree(tmp_dir, ignore_errors=True)

    return 0


if __name__ == "__main__":
    sys.exit(main())
