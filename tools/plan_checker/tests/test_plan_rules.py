import json
from pathlib import Path

import pytest

from plan_checker.cli import main
from plan_checker.rules import evaluate, meets_threshold

FIXTURES = Path(__file__).parent / "fixtures"


def _plan(*resources: dict) -> dict:
    return {"resource_changes": list(resources)}


def _rc(address: str, rtype: str, after: dict, actions: list[str] | None = None, unknown: dict | None = None) -> dict:
    return {
        "address": address,
        "mode": "managed",
        "type": rtype,
        "change": {
            "actions": actions or ["create"],
            "after": after,
            "after_unknown": unknown or {},
        },
    }


def ids(plan: dict) -> set[str]:
    return {item.rule_id for item in evaluate(plan)}


def test_compliant_bucket_and_instance_are_clean() -> None:
    plan = json.loads((FIXTURES / "compliant.json").read_text(encoding="utf-8"))
    assert evaluate(plan) == []


def test_public_bucket_and_missing_uniform() -> None:
    findings = evaluate(
        _plan(
            _rc(
                "google_storage_bucket.bad",
                "google_storage_bucket",
                {"uniform_bucket_level_access": False, "public_access_prevention": "inherited", "labels": {}},
            )
        )
    )
    assert {item.rule_id for item in findings} == {"GCS-001", "LBL-001", "CMEK-001"}
    assert any(item.severity == "high" for item in findings)


def test_unknown_bucket_is_low_not_a_crash() -> None:
    findings = evaluate(
        _plan(
            _rc(
                "google_storage_bucket.later",
                "google_storage_bucket",
                {
                    "uniform_bucket_level_access": None,
                    "labels": {"owner": "platform", "env": "prod", "cost-center": "security"},
                },
                unknown={"uniform_bucket_level_access": True, "public_access_prevention": True},
            )
        )
    )
    assert {item.rule_id for item in findings} == {"UNVERIFIED", "CMEK-001"}
    assert all(item.severity == "low" for item in findings)


def test_open_ssh_and_policy_rule() -> None:
    plan = _plan(
        _rc(
            "google_compute_firewall.bad",
            "google_compute_firewall",
            {"direction": "INGRESS", "source_ranges": ["0.0.0.0/0"], "allow": [{"protocol": "tcp", "ports": ["22"]}]},
        ),
        _rc(
            "google_compute_network_firewall_policy_rule.bad",
            "google_compute_network_firewall_policy_rule",
            {
                "direction": "INGRESS",
                "action": "allow",
                "match": [{"src_ip_ranges": ["::/0"], "layer4_configs": [{"ip_protocol": "all"}]}],
            },
        ),
    )
    assert ids(plan) == {"FW-001"}


def test_firewall_edges_are_ignored() -> None:
    plan = _plan(
        _rc(
            "google_compute_firewall.out",
            "google_compute_firewall",
            {
                "direction": "EGRESS",
                "destination_ranges": ["0.0.0.0/0"],
                "allow": [{"protocol": "tcp", "ports": ["22"]}],
            },
        ),
        _rc(
            "google_compute_firewall.off",
            "google_compute_firewall",
            {"disabled": True, "direction": "INGRESS", "source_ranges": ["0.0.0.0/0"], "allow": [{"protocol": "tcp"}]},
        ),
        _rc(
            "google_compute_firewall.https",
            "google_compute_firewall",
            {"direction": "INGRESS", "source_ranges": ["0.0.0.0/0"], "allow": [{"protocol": "tcp", "ports": ["443"]}]},
        ),
        _rc(
            "google_compute_firewall.udp",
            "google_compute_firewall",
            {
                "direction": "INGRESS",
                "source_ranges": ["0.0.0.0/0"],
                "allow": ["not-a-block", {"protocol": "udp", "ports": ["22"]}],
            },
        ),
        _rc(
            "google_compute_firewall.unknown",
            "google_compute_firewall",
            {"direction": "INGRESS"},
            unknown={"source_ranges": True},
        ),
    )
    assert ids(plan) == {"UNVERIFIED"}


def test_instance_public_default_sa_and_large_type() -> None:
    findings = evaluate(
        _plan(
            _rc(
                "google_compute_instance.bad",
                "google_compute_instance",
                {
                    "machine_type": "n2-standard-64",
                    "labels": {"owner": "platform", "env": "prod", "cost-center": "security"},
                    "network_interface": [{"access_config": [{"nat_ip": "203.0.113.10"}]}],
                    "service_account": [{"email": "123-compute@developer.gserviceaccount.com"}],
                },
            )
        )
    )
    assert {item.rule_id for item in findings} == {"VM-001", "VM-002", "FIN-001"}


def test_instance_unknowns_and_custom_machine() -> None:
    findings = evaluate(
        _plan(
            _rc(
                "google_compute_instance.later",
                "google_compute_instance",
                {
                    "labels": {"owner": "platform", "env": "prod", "cost-center": "security"},
                    "machine_type": "custom-8-32768",
                },
                unknown={"network_interface": True, "service_account": True},
            )
        )
    )
    assert {item.rule_id for item in findings} >= {"UNVERIFIED", "FIN-001"}


def test_empty_service_account_is_vm_002() -> None:
    assert "VM-002" in ids(
        _plan(
            _rc(
                "google_compute_instance.empty",
                "google_compute_instance",
                {
                    "machine_type": "e2-medium",
                    "labels": {"owner": "platform", "env": "nonprod", "cost-center": "security"},
                    "network_interface": [{"subnetwork": "prod"}],
                    "service_account": [],
                },
            )
        )
    )


def test_primitive_role_and_all_users() -> None:
    plan = _plan(
        _rc(
            "google_project_iam_binding.editor",
            "google_project_iam_binding",
            {"role": "roles/editor", "members": ["group:app@example.com"]},
        ),
        _rc(
            "google_storage_bucket_iam_member.public",
            "google_storage_bucket_iam_member",
            {"role": "roles/storage.objectViewer", "member": "allUsers"},
        ),
        _rc(
            "google_project_iam_policy.owner",
            "google_project_iam_policy",
            {"policy_data": '{"bindings":[{"role":"roles/owner","members":["allAuthenticatedUsers"]}]}'},
        ),
    )
    assert ids(plan) == {"IAM-001", "IAM-002"}


def test_unknown_iam_is_low() -> None:
    findings = evaluate(
        _plan(
            _rc("google_project_iam_member.later", "google_project_iam_member", {"role": None}, unknown={"role": True})
        )
    )
    assert findings[0].rule_id == "UNVERIFIED"


def test_cmek_missing_and_present() -> None:
    missing = ids(
        _plan(
            _rc(
                "google_storage_bucket.plain",
                "google_storage_bucket",
                {
                    "uniform_bucket_level_access": True,
                    "public_access_prevention": "enforced",
                    "labels": {"owner": "platform", "env": "shared", "cost-center": "security"},
                },
            ),
            _rc("google_sql_database_instance.db", "google_sql_database_instance", {"encryption_key_name": ""}),
            _rc("google_compute_disk.disk", "google_compute_disk", {}, unknown={"disk_encryption_key": True}),
        )
    )
    assert "CMEK-001" in missing
    assert "UNVERIFIED" in missing
    present = evaluate(
        _plan(
            _rc(
                "google_bigquery_dataset.enc",
                "google_bigquery_dataset",
                {
                    "labels": {"owner": "platform", "env": "prod", "cost-center": "security"},
                    "default_encryption_configuration": [
                        {"kms_key_name": "projects/p/locations/eu/keyRings/r/cryptoKeys/k"}
                    ],
                },
            )
        )
    )
    assert present == []


def test_service_account_key() -> None:
    assert ids(_plan(_rc("google_service_account_key.bad", "google_service_account_key", {}))) == {"IAM-003"}


def test_delete_noop_and_data_are_ignored() -> None:
    plan = {
        "resource_changes": [
            _rc("google_storage_bucket.gone", "google_storage_bucket", None, actions=["delete"]),
            _rc(
                "google_compute_firewall.same",
                "google_compute_firewall",
                {
                    "direction": "INGRESS",
                    "source_ranges": ["0.0.0.0/0"],
                    "allow": [{"protocol": "tcp", "ports": ["22"]}],
                },
                actions=["no-op"],
            ),
            {
                "address": "data.google_project.this",
                "mode": "data",
                "type": "google_project",
                "change": {"actions": ["read"]},
            },
            "not-a-change",
        ]
    }
    plan["resource_changes"][0]["change"]["after"] = None
    assert evaluate(plan) == []


def test_malformed_plan_does_not_crash() -> None:
    assert evaluate({}) == []
    assert evaluate({"resource_changes": "nope"}) == []


def test_threshold() -> None:
    findings = evaluate(
        _plan(
            _rc(
                "google_storage_bucket.plain",
                "google_storage_bucket",
                {
                    "uniform_bucket_level_access": True,
                    "public_access_prevention": "enforced",
                    "labels": {"owner": "platform", "env": "prod", "cost-center": "security"},
                },
            )
        )
    )
    assert findings[0].severity == "low"
    assert meets_threshold(findings, "high") is False
    assert meets_threshold(findings, "low") is True
    assert meets_threshold(findings, "none") is False


def test_cli_formats_and_exit_codes(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    plan = tmp_path / "plan.json"
    plan.write_text(
        json.dumps(
            _plan(
                _rc(
                    "google_compute_firewall.bad",
                    "google_compute_firewall",
                    {
                        "direction": "INGRESS",
                        "source_ranges": ["0.0.0.0/0"],
                        "allow": [{"protocol": "tcp", "ports": ["3389"]}],
                    },
                )
            )
        ),
        encoding="utf-8",
    )
    assert main([str(plan), "--format", "json", "--fail-on", "high"]) == 1
    payload = json.loads(capsys.readouterr().out)
    assert payload[0]["rule_id"] == "FW-001"
    assert main([str(plan), "--format", "sarif", "--fail-on", "none"]) == 0
    sarif = json.loads(capsys.readouterr().out)
    assert sarif["runs"][0]["results"][0]["ruleId"] == "FW-001"
    assert main([str(FIXTURES / "compliant.json"), "--format", "text", "--fail-on", "high"]) == 0
    assert "no findings" in capsys.readouterr().out


def test_cli_bad_input(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    broken = tmp_path / "broken.json"
    broken.write_text("[", encoding="utf-8")
    assert main([str(broken)]) == 2
    array = tmp_path / "array.json"
    array.write_text("[]", encoding="utf-8")
    assert main([str(array)]) == 2
    assert main([str(tmp_path / "missing.json")]) == 2
    capsys.readouterr()
