"""Offline policy demo.

Compares committed plan fixtures with Conftest and plan_checker. No cloud
credentials are used. ``examples/*/plan.json`` stands in for ``terraform show
-json`` because ``terraform plan`` needs a GCP project.
"""

from __future__ import annotations

import json
import shutil
import subprocess
import sys
from pathlib import Path

from plan_checker.rules import evaluate

ROOT = Path(__file__).resolve().parents[1]
COMPLIANT = ROOT / "examples" / "compliant" / "plan.json"
NONCOMPLIANT = ROOT / "examples" / "non-compliant" / "plan.json"
POLICIES = ROOT / "policies" / "opa"

EXPECTED_BAD = {
    ("GCS-001", "google_storage_bucket.public"),
    ("FW-001", "google_compute_firewall.ssh_world"),
    ("LBL-001", "google_compute_disk.unlabeled"),
    ("VM-001", "google_compute_instance.exposed"),
    ("VM-002", "google_compute_instance.exposed"),
    ("IAM-001", "google_project_iam_member.editor"),
    ("CMEK-001", "google_storage_bucket.no_cmek"),
}

CONFTEST_SNIPPETS = (
    "GCS-001 google_storage_bucket.public: uniform_bucket_level_access must be true",
    "GCS-001 google_storage_bucket.public: public_access_prevention must be enforced",
    "FW-001 google_compute_firewall.ssh_world: ingress allow of admin ports",
    "LBL-001 google_compute_disk.unlabeled: missing label owner",
    "LBL-001 google_compute_disk.unlabeled: missing label env",
    "LBL-001 google_compute_disk.unlabeled: missing label cost-center",
)


def pairs(plan_path: Path) -> set[tuple[str, str]]:
    plan = json.loads(plan_path.read_text(encoding="utf-8"))
    return {(item.rule_id, item.resource_address) for item in evaluate(plan)}


def conftest(plan_path: Path) -> subprocess.CompletedProcess[str]:
    binary = shutil.which("conftest")
    if binary is None:
        raise SystemExit("conftest is not on PATH")
    return subprocess.run(
        [binary, "test", str(plan_path), "-p", str(POLICIES), "--all-namespaces"],
        check=False,
        capture_output=True,
        text=True,
    )


def main() -> int:
    """Return 0 when the compliant plan passes and the bad plan fails as expected."""
    good = pairs(COMPLIANT)
    bad = pairs(NONCOMPLIANT)
    print("compliant plan_checker findings:", sorted(good) or "none")
    print("non-compliant plan_checker findings:")
    for rule_id, address in sorted(bad):
        print(f"  {rule_id} {address}")
    if good:
        print("expected the compliant plan to have no findings", file=sys.stderr)
        return 1
    if bad != EXPECTED_BAD:
        print("unexpected non-compliant findings", file=sys.stderr)
        print(f"  missing: {sorted(EXPECTED_BAD - bad)}", file=sys.stderr)
        print(f"  extra: {sorted(bad - EXPECTED_BAD)}", file=sys.stderr)
        return 1

    good_gate = conftest(COMPLIANT)
    bad_gate = conftest(NONCOMPLIANT)
    print(good_gate.stdout.strip() or "compliant conftest: pass")
    print(bad_gate.stdout.strip())
    if good_gate.returncode != 0:
        print(good_gate.stderr, file=sys.stderr)
        print("compliant plan failed Conftest", file=sys.stderr)
        return 1
    if bad_gate.returncode == 0:
        print("non-compliant plan was accepted by Conftest", file=sys.stderr)
        return 1
    combined = bad_gate.stdout + bad_gate.stderr
    missing = [snippet for snippet in CONFTEST_SNIPPETS if snippet not in combined]
    if missing:
        print("Conftest output missed expected violations:", file=sys.stderr)
        for snippet in missing:
            print(f"  {snippet}", file=sys.stderr)
        return 1
    print("policy-demo: compliant passed, non-compliant failed for the expected controls")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
