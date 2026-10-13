"""Plan rules.

Each rule looks at one resource change from ``terraform show -json`` and
returns findings. Deletes and no-ops are ignored. Unknown values become a
low-severity unverifiable finding instead of a crash or a hard failure.
"""

from __future__ import annotations

from collections.abc import Iterable, Mapping
from dataclasses import asdict, dataclass

SEVERITY_RANK = {"low": 1, "medium": 2, "high": 3}

LABELABLE = {
    "google_storage_bucket",
    "google_compute_instance",
    "google_compute_disk",
    "google_bigquery_dataset",
    "google_sql_database_instance",
    "google_project",
    "google_vertex_ai_endpoint",
}
REQUIRED_LABELS = ("owner", "env", "cost-center")
FIREWALL_TYPES = {
    "google_compute_firewall",
    "google_compute_firewall_policy_rule",
    "google_compute_network_firewall_policy_rule",
}
WORLD = {"0.0.0.0/0", "::/0"}
PRIMITIVE_ROLES = {"roles/owner", "roles/editor"}
PUBLIC_MEMBERS = {"allUsers", "allAuthenticatedUsers"}


@dataclass(frozen=True)
class Finding:
    """One policy finding for a single resource address."""

    rule_id: str
    severity: str
    resource_address: str
    message: str
    remediation: str
    catalog_id: str

    def to_dict(self) -> dict[str, str]:
        return asdict(self)


def evaluate(plan: Mapping[str, object]) -> list[Finding]:
    """Return findings for every applicable resource change in ``plan``."""

    findings: list[Finding] = []
    for change in _managed_changes(plan):
        findings.extend(_rules_for(change))
    return findings


def meets_threshold(findings: Iterable[Finding], fail_on: str) -> bool:
    """True when any finding is at least as severe as ``fail_on``.

    ``none`` never matches.
    """

    if fail_on == "none":
        return False
    minimum = SEVERITY_RANK[fail_on]
    return any(SEVERITY_RANK[finding.severity] >= minimum for finding in findings)


def _managed_changes(plan: Mapping[str, object]) -> list[Mapping[str, object]]:
    raw = plan.get("resource_changes") or []
    if not isinstance(raw, list):
        return []
    selected: list[Mapping[str, object]] = []
    for item in raw:
        if not isinstance(item, Mapping):
            continue
        if item.get("mode") != "managed":
            continue
        change = item.get("change") if isinstance(item.get("change"), Mapping) else {}
        actions = list(change.get("actions") or [])
        if actions in (["delete"], ["no-op"]):
            continue
        selected.append(item)
    return selected


def _rules_for(resource: Mapping[str, object]) -> list[Finding]:
    change = resource.get("change") if isinstance(resource.get("change"), Mapping) else {}
    after = change.get("after") if isinstance(change.get("after"), Mapping) else {}
    unknown = change.get("after_unknown") if isinstance(change.get("after_unknown"), Mapping) else {}
    address = str(resource.get("address") or resource.get("name") or "<unknown>")
    rtype = str(resource.get("type") or "")
    findings: list[Finding] = []
    findings.extend(_bucket(rtype, address, after, unknown))
    findings.extend(_firewall(rtype, address, after, unknown))
    findings.extend(_instance(rtype, address, after, unknown))
    findings.extend(_iam(rtype, address, after, unknown))
    findings.extend(_labels(rtype, address, after, unknown))
    findings.extend(_cmek(rtype, address, after, unknown))
    findings.extend(_sa_key(rtype, address))
    findings.extend(_machine(rtype, address, after, unknown))
    return findings


def _unverifiable(address: str, field: str) -> Finding:
    return Finding(
        rule_id="UNVERIFIED",
        severity="low",
        resource_address=address,
        message=f"{field} is unknown after apply and cannot be checked",
        remediation=f"Set {field} to a known value so the plan can be reviewed.",
        catalog_id="UNVERIFIED",
    )


def _bucket(rtype: str, address: str, after: Mapping[str, object], unknown: Mapping[str, object]) -> list[Finding]:
    if rtype != "google_storage_bucket":
        return []
    findings: list[Finding] = []
    if unknown.get("uniform_bucket_level_access") is True:
        findings.append(_unverifiable(address, "uniform_bucket_level_access"))
    elif after.get("uniform_bucket_level_access") is not True:
        findings.append(
            Finding(
                rule_id="GCS-001",
                severity="high",
                resource_address=address,
                message="uniform_bucket_level_access must be true",
                remediation="Use modules/gcs-bucket or set uniform_bucket_level_access = true.",
                catalog_id="GCS-001",
            )
        )
    if unknown.get("public_access_prevention") is True:
        findings.append(_unverifiable(address, "public_access_prevention"))
    elif after.get("public_access_prevention") != "enforced":
        findings.append(
            Finding(
                rule_id="GCS-001",
                severity="high",
                resource_address=address,
                message="public_access_prevention must be enforced",
                remediation='Set public_access_prevention = "enforced".',
                catalog_id="GCS-001",
            )
        )
    return findings


def _firewall(rtype: str, address: str, after: Mapping[str, object], unknown: Mapping[str, object]) -> list[Finding]:
    if rtype not in FIREWALL_TYPES or after.get("disabled") is True:
        return []
    if unknown.get("source_ranges") is True or unknown.get("match") is True:
        return [_unverifiable(address, "firewall source")]
    direction = str(after.get("direction") or "INGRESS")
    if direction != "INGRESS":
        return []
    if rtype == "google_compute_firewall":
        ranges = _as_list(after.get("source_ranges"))
        allows = _as_list(after.get("allow"))
        open_admin = _world(ranges) and any(_admin_from_allow(item) for item in allows)
    else:
        match = _first_map(after.get("match"))
        action = str(after.get("action") or "").lower()
        open_admin = (
            action == "allow"
            and _world(_as_list(match.get("src_ip_ranges")))
            and any(_admin_from_layer4(item) for item in _as_list(match.get("layer4_configs")))
        )
    if not open_admin:
        return []
    return [
        Finding(
            rule_id="FW-001",
            severity="high",
            resource_address=address,
            message="ingress allow of admin ports from 0.0.0.0/0 or ::/0",
            remediation="Allow 35.235.240.0/20 to instances tagged iap-ssh. Use modules/firewall-rule.",
            catalog_id="FW-001",
        )
    ]


def _instance(rtype: str, address: str, after: Mapping[str, object], unknown: Mapping[str, object]) -> list[Finding]:
    if rtype != "google_compute_instance":
        return []
    findings: list[Finding] = []
    if unknown.get("network_interface") is True:
        findings.append(_unverifiable(address, "network_interface"))
    else:
        for nic in _as_list(after.get("network_interface")):
            if _as_list(nic.get("access_config") if isinstance(nic, Mapping) else None):
                findings.append(
                    Finding(
                        rule_id="VM-001",
                        severity="high",
                        resource_address=address,
                        message="access_config assigns an external IP",
                        remediation="Remove access_config and use Identity-Aware Proxy.",
                        catalog_id="VM-001",
                    )
                )
                break
    if unknown.get("service_account") is True:
        findings.append(_unverifiable(address, "service_account"))
    else:
        accounts = _as_list(after.get("service_account"))
        emails = [str(item.get("email") or "") for item in accounts if isinstance(item, Mapping)]
        if not emails or any(_default_compute_sa(email) for email in emails):
            findings.append(
                Finding(
                    rule_id="VM-002",
                    severity="high",
                    resource_address=address,
                    message="service account is empty or the default Compute Engine account",
                    remediation="Set service_account.email to a dedicated account. Do not create a key.",
                    catalog_id="VM-002",
                )
            )
    return findings


def _iam(rtype: str, address: str, after: Mapping[str, object], unknown: Mapping[str, object]) -> list[Finding]:
    if not rtype.endswith(("_iam_member", "_iam_binding", "_iam_policy")):
        return []
    if unknown.get("role") is True or unknown.get("member") is True or unknown.get("policy_data") is True:
        return [_unverifiable(address, "iam binding")]
    findings: list[Finding] = []
    role = str(after.get("role") or "")
    policy_data = str(after.get("policy_data") or "")
    if role in PRIMITIVE_ROLES or "roles/owner" in policy_data or "roles/editor" in policy_data:
        findings.append(
            Finding(
                rule_id="IAM-001",
                severity="high",
                resource_address=address,
                message="role is owner or editor",
                remediation="Bind a custom role or a narrower predefined role. See landing-zone/40-iam.",
                catalog_id="IAM-001",
            )
        )
    members = [str(after.get("member") or "")] + [str(item) for item in _as_list(after.get("members"))]
    if any(member in PUBLIC_MEMBERS for member in members) or any(name in policy_data for name in PUBLIC_MEMBERS):
        findings.append(
            Finding(
                rule_id="IAM-002",
                severity="high",
                resource_address=address,
                message="binding includes allUsers or allAuthenticatedUsers",
                remediation="Bind a Google group. Remove allUsers and allAuthenticatedUsers.",
                catalog_id="IAM-002",
            )
        )
    return findings


def _labels(rtype: str, address: str, after: Mapping[str, object], unknown: Mapping[str, object]) -> list[Finding]:
    if rtype not in LABELABLE:
        return []
    if unknown.get("labels") is True:
        return [_unverifiable(address, "labels")]
    labels = after.get("labels") if isinstance(after.get("labels"), Mapping) else {}
    missing = [key for key in REQUIRED_LABELS if not str(labels.get(key) or "")]
    if not missing:
        return []
    return [
        Finding(
            rule_id="LBL-001",
            severity="medium",
            resource_address=address,
            message=f"missing labels: {', '.join(missing)}",
            remediation="Set owner, env, and cost-center. env must be prod, nonprod, or shared.",
            catalog_id="LBL-001",
        )
    ]


def _cmek(rtype: str, address: str, after: Mapping[str, object], unknown: Mapping[str, object]) -> list[Finding]:
    checks = {
        "google_storage_bucket": ("encryption", "default_kms_key_name", "bucket is missing a Cloud KMS key"),
        "google_bigquery_dataset": (
            "default_encryption_configuration",
            "kms_key_name",
            "dataset is missing a Cloud KMS key",
        ),
        "google_compute_disk": ("disk_encryption_key", "kms_key_self_link", "disk is missing a Cloud KMS key"),
        "google_sql_database_instance": (None, "encryption_key_name", "Cloud SQL instance is missing a Cloud KMS key"),
    }
    if rtype not in checks:
        return []
    block_name, key_name, message = checks[rtype]
    if block_name and unknown.get(block_name) is True:
        return [_unverifiable(address, block_name)]
    if block_name is None:
        present = bool(after.get(key_name))
    else:
        block = _first_map(after.get(block_name))
        present = bool(block.get(key_name))
    if present:
        return []
    return [
        Finding(
            rule_id="CMEK-001",
            severity="low",
            resource_address=address,
            message=message,
            remediation="Pass the crypto key id from modules/kms-key. This control is advisory.",
            catalog_id="CMEK-001",
        )
    ]


def _sa_key(rtype: str, address: str) -> list[Finding]:
    if rtype != "google_service_account_key":
        return []
    return [
        Finding(
            rule_id="IAM-003",
            severity="high",
            resource_address=address,
            message="service account keys are not allowed",
            remediation="Delete the key and use Workload Identity Federation.",
            catalog_id="IAM-003",
        )
    ]


def _machine(rtype: str, address: str, after: Mapping[str, object], unknown: Mapping[str, object]) -> list[Finding]:
    if rtype != "google_compute_instance":
        return []
    if unknown.get("machine_type") is True:
        return [_unverifiable(address, "machine_type")]
    machine_type = str(after.get("machine_type") or "")
    expensive = "custom-" in machine_type or machine_type.endswith(("-32", "-48", "-64", "-96", "-128"))
    if not expensive:
        return []
    return [
        Finding(
            rule_id="FIN-001",
            severity="low",
            resource_address=address,
            message=f"machine type {machine_type} looks expensive",
            remediation="Confirm the cost with the budget owner before apply.",
            catalog_id="FIN-001",
        )
    ]


def _as_list(value: object) -> list[object]:
    if value is None:
        return []
    if isinstance(value, list):
        return value
    return [value]


def _first_map(value: object) -> Mapping[str, object]:
    items = [item for item in _as_list(value) if isinstance(item, Mapping)]
    if not items:
        return {}
    return items[0]


def _world(ranges: list[object]) -> bool:
    return any(str(item) in WORLD for item in ranges)


def _admin_from_allow(item: object) -> bool:
    if not isinstance(item, Mapping):
        return False
    return _admin_ports(str(item.get("protocol") or ""), _as_list(item.get("ports")))


def _admin_from_layer4(item: object) -> bool:
    if not isinstance(item, Mapping):
        return False
    return _admin_ports(str(item.get("ip_protocol") or ""), _as_list(item.get("ports")))


def _admin_ports(protocol: str, ports: list[object]) -> bool:
    protocol = protocol.lower()
    if protocol == "all":
        return True
    if protocol != "tcp":
        return False
    if not ports:
        return True
    return any(str(port) in {"22", "3389"} for port in ports)


def _default_compute_sa(email: str) -> bool:
    return email == "" or email.endswith("-compute@developer.gserviceaccount.com")
