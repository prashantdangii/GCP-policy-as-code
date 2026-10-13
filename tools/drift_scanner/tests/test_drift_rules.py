import json
from pathlib import Path

from drift_scanner.cli import load_live, main
from drift_scanner.report import render
from drift_scanner.rules import scan

FIXTURE = Path(__file__).parent / "fixtures" / "assets_noncompliant.json"


def test_fixture_flags_gap_and_closed_controls() -> None:
    findings = scan(json.loads(FIXTURE.read_text(encoding="utf-8")))
    by_id = {item.catalog_id for item in findings}
    assert {"GCS-001", "FW-001", "VM-001", "IAM-003", "IAM-001", "IAM-002", "LBL-001", "ORG-012", "NET-002"} <= by_id
    gaps = [item for item in findings if item.preventive_gap]
    assert gaps and all(item.catalog_id == "NET-002" for item in gaps)
    assert all(item.preventive_exists for item in findings if item.catalog_id == "IAM-003")


def test_clean_and_ignored_assets() -> None:
    inventory = {
        "resources": [
            {
                "name": "good-bucket",
                "assetType": "storage.googleapis.com/Bucket",
                "project": "projects/app",
                "location": "eu",
                "labels": {"owner": "platform", "env": "prod", "cost-center": "security"},
                "additionalAttributes": {"uniform_bucket_level_access": True, "public_access_prevention": "enforced"},
            },
            {
                "name": "system-key",
                "assetType": "iam.googleapis.com/ServiceAccountKey",
                "project": "projects/app",
                "data": {"keyType": "SYSTEM_MANAGED"},
            },
            {
                "name": "logged-subnet",
                "assetType": "compute.googleapis.com/Subnetwork",
                "project": "projects/net",
                "location": "global",
                "data": {"log_config": {"enabled": True}},
            },
            {
                "name": "egress",
                "assetType": "compute.googleapis.com/Firewall",
                "project": "projects/net",
                "data": {
                    "direction": "EGRESS",
                    "source_ranges": ["0.0.0.0/0"],
                    "allowed": [{"protocol": "tcp", "ports": ["22"]}],
                },
            },
            {
                "name": "private-vm",
                "assetType": "compute.googleapis.com/Instance",
                "project": "projects/app",
                "location": "europe-west1-b",
                "labels": {"owner": "platform", "env": "prod", "cost-center": "security"},
                "data": {"network_interfaces": [{"subnetwork": "prod"}]},
            },
        ],
        "iam_policies": [
            {"policy": {"bindings": ["nope", {"role": "roles/viewer", "members": ["group:security@example.com"]}]}}
        ],
    }
    assert scan(inventory) == []


def test_reports_include_gap_language() -> None:
    findings = scan(json.loads(FIXTURE.read_text(encoding="utf-8")))
    markdown = render(findings, "md", "projects/ORG_PLACEHOLDER")
    html = render(findings, "html", "projects/ORG_PLACEHOLDER")
    document = json.loads(render(findings, "json", "offline"))
    assert "preventive gap" in markdown
    assert "Preventive gap" in html
    assert document["summary"]["preventive_gaps"] >= 1
    assert render([], "md", "offline").count("None.") >= 1


def test_cli_offline_and_bad_scope(capsys, tmp_path: Path) -> None:
    assert main(["--input", str(FIXTURE), "--format", "md", "--scope", "projects/demo"]) == 0
    assert "NET-002" in capsys.readouterr().out
    try:
        load_live("not-a-scope")
    except RuntimeError as exc:
        assert "live mode" in str(exc)
    else:
        raise AssertionError("expected RuntimeError")
    output = tmp_path / "report.html"
    assert main(["--input", str(FIXTURE), "--format", "html", "--output", str(output)]) == 0
    assert "Drift report" in output.read_text(encoding="utf-8")
    assert main(["--input", str(tmp_path / "missing.json")]) == 2
