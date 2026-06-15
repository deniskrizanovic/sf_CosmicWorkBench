"""Tests for diff_org_changes.py — TDD migration of diff-org-changes.sh to Python."""
import json
import os
import tempfile
from pathlib import Path
from unittest.mock import MagicMock, patch

import pytest

import sys
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from diff_org_changes import (
    detect_package_dir,
    normalise_flow,
    rewrite_flow_manifest,
    normalise_apex,
    normalise_dashboard,
    normalise_field,
    normalise_object,
    normalise_validation_rule,
    generate_manifest,
    retrieve_metadata,
    run_diff,
    main,
)


# ---------------------------------------------------------------------------
# Unit 1 — detect_package_dir
# ---------------------------------------------------------------------------

class TestDetectPackageDir:
    def test_returns_path_from_sfdx_project_json(self, tmp_path):
        proj = {"packageDirectories": [{"path": "src", "default": True}]}
        (tmp_path / "sfdx-project.json").write_text(json.dumps(proj))
        assert detect_package_dir(str(tmp_path)) == "src"

    def test_strips_trailing_slash(self, tmp_path):
        proj = {"packageDirectories": [{"path": "force-app/", "default": True}]}
        (tmp_path / "sfdx-project.json").write_text(json.dumps(proj))
        assert detect_package_dir(str(tmp_path)) == "force-app"

    def test_no_sfdx_project_json_returns_src(self, tmp_path):
        assert detect_package_dir(str(tmp_path)) == "src"


# ---------------------------------------------------------------------------
# Unit 2 — normalise_flow
# ---------------------------------------------------------------------------

class TestNormaliseFlow:
    def test_strips_location_and_status(self, tmp_path):
        flow_xml = """\
<?xml version="1.0" encoding="UTF-8"?>
<Flow xmlns="http://soap.sforce.com/2006/04/metadata">
    <actionCalls>
        <name>Action1</name>
        <locationX>100</locationX>
        <locationY>200</locationY>
        <status>Active</status>
    </actionCalls>
</Flow>
"""
        p = tmp_path / "test.flow-meta.xml"
        p.write_text(flow_xml)
        result = normalise_flow(str(p))
        assert "locationX" not in result
        assert "locationY" not in result
        assert "status" not in result
        assert "Action1" in result

    def test_sorts_elements_by_tag_and_name(self, tmp_path):
        flow_xml = """\
<?xml version="1.0" encoding="UTF-8"?>
<Flow xmlns="http://soap.sforce.com/2006/04/metadata">
    <variables>
        <name>Zulu</name>
    </variables>
    <variables>
        <name>Alpha</name>
    </variables>
</Flow>
"""
        p = tmp_path / "test.flow-meta.xml"
        p.write_text(flow_xml)
        result = normalise_flow(str(p))
        alpha_pos = result.find("Alpha")
        zulu_pos = result.find("Zulu")
        assert alpha_pos < zulu_pos

    def test_returns_string(self, tmp_path):
        flow_xml = """\
<?xml version="1.0" encoding="UTF-8"?>
<Flow xmlns="http://soap.sforce.com/2006/04/metadata">
    <variables>
        <name>X</name>
    </variables>
</Flow>
"""
        p = tmp_path / "test.flow-meta.xml"
        p.write_text(flow_xml)
        result = normalise_flow(str(p))
        assert isinstance(result, str)
        assert len(result) > 0


# ---------------------------------------------------------------------------
# Unit 3 — rewrite_flow_manifest
# ---------------------------------------------------------------------------

class TestRewriteFlowManifest:
    def test_rewrites_member_with_active_version(self, tmp_path):
        manifest = """\
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>MyFlow</members>
        <name>Flow</name>
    </types>
</Package>
"""
        p = tmp_path / "package.xml"
        p.write_text(manifest)

        mock_runner = MagicMock()
        mock_runner.return_value = MagicMock(
            returncode=0,
            stdout=json.dumps({
                "result": {
                    "records": [{"ActiveVersion": {"VersionNumber": 3}}]
                }
            }),
        )

        rewrite_flow_manifest(str(p), "myorg", runner=mock_runner)
        content = p.read_text()
        assert "<members>MyFlow-3</members>" in content

    def test_no_records_manifest_unchanged(self, tmp_path):
        manifest = """\
<?xml version="1.0" encoding="UTF-8"?>
<Package xmlns="http://soap.sforce.com/2006/04/metadata">
    <types>
        <members>MyFlow</members>
        <name>Flow</name>
    </types>
</Package>
"""
        p = tmp_path / "package.xml"
        p.write_text(manifest)
        original = manifest

        mock_runner = MagicMock()
        mock_runner.return_value = MagicMock(
            returncode=0,
            stdout=json.dumps({"result": {"records": []}}),
        )

        rewrite_flow_manifest(str(p), "myorg", runner=mock_runner)
        content = p.read_text()
        assert "<members>MyFlow</members>" in content


# ---------------------------------------------------------------------------
# Unit 4 — normalise_apex
# ---------------------------------------------------------------------------

class TestNormaliseApex:
    def test_adds_trailing_newline(self, tmp_path):
        src = tmp_path / "Test.cls"
        dest = tmp_path / "Test_norm.cls"
        src.write_text("public class Test {}")  # no trailing newline
        normalise_apex(str(src), str(dest))
        content = dest.read_text()
        assert content.endswith("\n")

    def test_preserves_single_trailing_newline(self, tmp_path):
        src = tmp_path / "Test.cls"
        dest = tmp_path / "Test_norm.cls"
        src.write_text("public class Test {}\n")
        normalise_apex(str(src), str(dest))
        content = dest.read_text()
        assert content == "public class Test {}\n"
        assert not content.endswith("\n\n")


# ---------------------------------------------------------------------------
# Unit 5 — normalise_dashboard
# ---------------------------------------------------------------------------

class TestNormaliseDashboard:
    def test_strips_owner_line(self, tmp_path):
        src = tmp_path / "dash.dashboard-meta.xml"
        dest = tmp_path / "dash_norm.dashboard-meta.xml"
        src.write_text("<dashboard>\n    <owner>foo</owner>\n    <title>Test</title>\n</dashboard>\n")
        normalise_dashboard(str(src), str(dest))
        content = dest.read_text()
        assert "<owner>" not in content
        assert "<title>Test</title>" in content

    def test_strips_running_user_line(self, tmp_path):
        src = tmp_path / "dash.dashboard-meta.xml"
        dest = tmp_path / "dash_norm.dashboard-meta.xml"
        src.write_text("<dashboard>\n    <runningUser>bar</runningUser>\n    <title>Test</title>\n</dashboard>\n")
        normalise_dashboard(str(src), str(dest))
        content = dest.read_text()
        assert "<runningUser>" not in content
        assert "<title>Test</title>" in content


# ---------------------------------------------------------------------------
# Unit 6 — normalise_field
# ---------------------------------------------------------------------------

class TestNormaliseField:
    def test_replaces_quot_entity(self, tmp_path):
        src = tmp_path / "field.field-meta.xml"
        dest = tmp_path / "field_norm.field-meta.xml"
        src.write_text('<field>\n    <label>&quot;Hello&quot;</label>\n</field>\n')
        normalise_field(str(src), str(dest))
        content = dest.read_text()
        assert '&quot;' not in content
        assert '"Hello"' in content


# ---------------------------------------------------------------------------
# Unit 7 — normalise_object
# ---------------------------------------------------------------------------

class TestNormaliseObject:
    def test_strips_record_type_track_history(self, tmp_path):
        src = tmp_path / "obj.object-meta.xml"
        dest = tmp_path / "obj_norm.object-meta.xml"
        src.write_text(
            "<object>\n"
            "    <recordTypeTrackHistory>true</recordTypeTrackHistory>\n"
            "    <label>Test</label>\n"
            "</object>\n"
        )
        normalise_object(str(src), str(dest))
        content = dest.read_text()
        assert "<recordTypeTrackHistory>" not in content
        assert "<label>Test</label>" in content


# ---------------------------------------------------------------------------
# Unit 8 — normalise_validation_rule
# ---------------------------------------------------------------------------

class TestNormaliseValidationRule:
    def test_converts_cdata_to_xml_entities(self, tmp_path):
        src = tmp_path / "rule.validationRule-meta.xml"
        dest = tmp_path / "rule_norm.validationRule-meta.xml"
        src.write_text(
            "<ValidationRule>\n"
            "    <errorConditionFormula><![CDATA[Level__c < 1]]></errorConditionFormula>\n"
            "</ValidationRule>\n"
        )
        normalise_validation_rule(str(src), str(dest))
        content = dest.read_text()
        assert "<![CDATA[" not in content
        assert "]]>" not in content
        assert "&lt;" in content

    def test_converts_gt_in_cdata(self, tmp_path):
        src = tmp_path / "rule.validationRule-meta.xml"
        dest = tmp_path / "rule_norm.validationRule-meta.xml"
        src.write_text(
            "<ValidationRule>\n"
            "    <errorConditionFormula><![CDATA[Level__c > 10]]></errorConditionFormula>\n"
            "</ValidationRule>\n"
        )
        normalise_validation_rule(str(src), str(dest))
        content = dest.read_text()
        assert "<![CDATA[" not in content
        assert "&gt;" in content

    def test_no_cdata_unchanged(self, tmp_path):
        src = tmp_path / "rule.validationRule-meta.xml"
        dest = tmp_path / "rule_norm.validationRule-meta.xml"
        original = (
            "<ValidationRule>\n"
            "    <errorConditionFormula>ISBLANK(Name)</errorConditionFormula>\n"
            "</ValidationRule>\n"
        )
        src.write_text(original)
        normalise_validation_rule(str(src), str(dest))
        assert dest.read_text() == original

    def test_multiline_cdata(self, tmp_path):
        src = tmp_path / "rule.validationRule-meta.xml"
        dest = tmp_path / "rule_norm.validationRule-meta.xml"
        src.write_text(
            "<ValidationRule>\n"
            "    <errorConditionFormula><![CDATA[\n"
            "        Level__c < 1 &&\n"
            "        Parent__c > 0\n"
            "    ]]></errorConditionFormula>\n"
            "</ValidationRule>\n"
        )
        normalise_validation_rule(str(src), str(dest))
        content = dest.read_text()
        assert "<![CDATA[" not in content
        assert "&lt;" in content
        assert "&gt;" in content


# ---------------------------------------------------------------------------
# Unit 9 — generate_manifest (assert call args only)  # noqa: E265
# ---------------------------------------------------------------------------

class TestGenerateManifest:
    def test_calls_sf_with_correct_args(self, tmp_path):
        mock_runner = MagicMock()
        mock_runner.return_value = MagicMock(returncode=0)
        source_dir = str(tmp_path / "src")
        output_path = str(tmp_path / "diff-package.xml")

        generate_manifest(source_dir, output_path, runner=mock_runner)

        call_args = mock_runner.call_args
        cmd = call_args[0][0]
        assert "sf" in cmd
        assert "project" in cmd
        assert "generate" in cmd
        assert "manifest" in cmd
        assert "--source-dir" in cmd
        assert source_dir in cmd
        assert "--name" in cmd
        assert "diff-package" in cmd
        assert "--output-dir" in cmd


# ---------------------------------------------------------------------------
# Unit 9 — retrieve_metadata (assert call args only)
# ---------------------------------------------------------------------------

class TestRetrieveMetadata:
    def test_calls_sf_with_correct_args(self, tmp_path):
        mock_runner = MagicMock()
        mock_runner.return_value = MagicMock(returncode=0)
        manifest_path = str(tmp_path / "diff-package.xml")
        tmp_project_dir = str(tmp_path / "project")

        retrieve_metadata(manifest_path, "myorg", tmp_project_dir, runner=mock_runner)

        call_args = mock_runner.call_args
        cmd = call_args[0][0]
        assert "sf" in cmd
        assert "project" in cmd
        assert "retrieve" in cmd
        assert "start" in cmd
        assert "--target-org" in cmd
        assert "myorg" in cmd
        assert "--manifest" in cmd
        assert manifest_path in cmd
        kwargs = call_args[1] if len(call_args) > 1 else call_args.kwargs
        assert kwargs.get("cwd") == tmp_project_dir


# ---------------------------------------------------------------------------
# Unit 10 — run_diff
# ---------------------------------------------------------------------------

class TestRunDiff:
    def test_returns_string(self, tmp_path):
        org_dir = tmp_path / "org"
        local_dir = tmp_path / "local"
        org_dir.mkdir()
        local_dir.mkdir()
        # Create matching structure
        (org_dir / "classes").mkdir()
        (local_dir / "classes").mkdir()
        (org_dir / "classes" / "A.cls").write_text("class A {}")
        (local_dir / "classes" / "A.cls").write_text("class A {}")

        norm_dirs = {
            "flows_org": str(tmp_path / "fn_org"),
            "flows_local": str(tmp_path / "fn_local"),
            "apex_org": str(tmp_path / "an_org"),
            "apex_local": str(tmp_path / "an_local"),
            "dash_org": str(tmp_path / "dn_org"),
            "dash_local": str(tmp_path / "dn_local"),
            "field_org": str(tmp_path / "fdn_org"),
            "field_local": str(tmp_path / "fdn_local"),
            "obj_org": str(tmp_path / "on_org"),
            "obj_local": str(tmp_path / "on_local"),
            "vr_org": str(tmp_path / "vr_org"),
            "vr_local": str(tmp_path / "vr_local"),
        }
        for d in norm_dirs.values():
            os.makedirs(d, exist_ok=True)

        result = run_diff(str(org_dir), str(local_dir), norm_dirs)
        assert isinstance(result, str)

    def test_single_file_path(self, tmp_path):
        org_dir = tmp_path / "org"
        local_dir = tmp_path / "local"
        org_dir.mkdir()
        local_dir.mkdir()
        (org_dir / "classes").mkdir()
        (local_dir / "classes").mkdir()
        (org_dir / "classes" / "A.cls").write_text("class A { // org }")
        (local_dir / "classes" / "A.cls").write_text("class A { // local }")

        norm_dirs = {
            "flows_org": str(tmp_path / "fn_org"),
            "flows_local": str(tmp_path / "fn_local"),
            "apex_org": str(tmp_path / "an_org"),
            "apex_local": str(tmp_path / "an_local"),
            "dash_org": str(tmp_path / "dn_org"),
            "dash_local": str(tmp_path / "dn_local"),
            "field_org": str(tmp_path / "fdn_org"),
            "field_local": str(tmp_path / "fdn_local"),
            "obj_org": str(tmp_path / "on_org"),
            "obj_local": str(tmp_path / "on_local"),
            "vr_org": str(tmp_path / "vr_org"),
            "vr_local": str(tmp_path / "vr_local"),
        }
        for d in norm_dirs.values():
            os.makedirs(d, exist_ok=True)
        # Put normalised apex files
        (Path(norm_dirs["apex_org"]) / "A.cls").write_text("class A { // org }\n")
        (Path(norm_dirs["apex_local"]) / "A.cls").write_text("class A { // local }\n")

        result = run_diff(str(org_dir), str(local_dir), norm_dirs, file_path="classes/A.cls")
        assert isinstance(result, str)
        # Should contain some diff output since files differ
        assert len(result) > 0


# ---------------------------------------------------------------------------
# Unit 11 — main smoke test
# ---------------------------------------------------------------------------

class TestMain:
    @patch("diff_org_changes.subprocess.run")
    def test_smoke_returns_zero(self, mock_run, tmp_path, monkeypatch):
        # Set up minimal project structure
        monkeypatch.chdir(tmp_path)
        proj = {"packageDirectories": [{"path": "src", "default": True}]}
        (tmp_path / "sfdx-project.json").write_text(json.dumps(proj))

        # Create local source dir with a flow
        local_src = tmp_path / "src" / "main" / "default" / "flows"
        local_src.mkdir(parents=True)
        flow_xml = '<?xml version="1.0" encoding="UTF-8"?>\n<Flow xmlns="http://soap.sforce.com/2006/04/metadata"><variables><name>X</name></variables></Flow>\n'
        (local_src / "Test.flow-meta.xml").write_text(flow_xml)

        # Mock all subprocess calls
        mock_run.return_value = MagicMock(
            returncode=0,
            stdout=json.dumps({"result": {"records": []}}),
        )

        result = main(["--org", "testorg"])
        assert result == 0
