"""Inventory rules.

Offline fixtures and live Cloud Asset Inventory results are normalized to the
same shape before these rules run. A finding whose catalog id has no Sentinel
or OPA control sets ``preventive_gap`` so the detective loop has somewhere to go.
"""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import asdict, dataclass

WORLD = {"0.0.0.0/0", "::/0"}
PRIMITIVE_ROLES = {"roles/owner", "roles/editor"}
PUBLIC_MEMBERS = {"allUsers", "allAuthenticatedUsers"}
REQUIRED_LABELS = ("owner", "env", "cost-center")

# catalog id, whether a preventive control already exists
COVERAGE: dict[str, tuple[str, bool]] = {
    "GCS-001": ("GCS-001", True),
    "FW-001": ("FW-001", True),
    "IAM-001": ("IAM-001", True),
    "IAM-002": ("IAM-002", True),
    "IAM-003": ("IAM-003", True),
    "VM-001": ("VM-001", True),
    "LBL-001": ("LBL-001", True),
    "ORG-012": ("ORG-012", True),
    "NET-002": ("NET-002", False),
}


@dataclass(frozen=True)
class Finding:
    """One live or fixture finding."""

    rule_id: str
    severity: str
    project: str
    asset: str
    message: str
    catalog_id: str
    preventive_exists: bool
    preventive_gap: bool

    def to_dict(self) -> dict[str, object]:
        return asdict(self)


def scan(inventory: Mapping[str, object], allowed_locations: list[str] | None = None) -> list[Finding]:
    """Scan a normalized inventory document."""

    allowed = {item.lower() for item in (allowed_locations or _default_locations())}
    resources = [item for item in _as_list(inventory.get("resources")) if isinstance(item, Mapping)]
    policies = [item for item in _as_list(inventory.get("iam_policies")) if isinstance(item, Mapping)]
    findings: list[Finding] = []
    for asset in resources:
        findings.extend(_asset_findings(asset, allowed))
    for policy in policies:
        findings.extend(_iam_findings(policy))
    return findings


def _default_locations() -> list[str]:
    return ["eu", "us", "europe-west1", "europe-west2", "us-central1", "us-east1", "global"]


def _asset_findings(asset: Mapping[str, object], allowed: set[str]) -> list[Finding]:
    asset_type = str(asset.get("assetType") or asset.get("asset_type") or "")
    data = asset.get("data") if isinstance(asset.get("data"), Mapping) else {}
    extra = asset.get("additionalAttributes") if isinstance(asset.get("additionalAttributes"), Mapping) else {}
    merged = {**dict(extra), **dict(data)}
    name = str(asset.get("name") or asset.get("displayName") or "<unknown>")
    project = str(asset.get("project") or "unknown")
    findings: list[Finding] = []

    if asset_type == "storage.googleapis.com/Bucket":
        findings.extend(_bucket(name, project, merged))
    elif asset_type == "compute.googleapis.com/Firewall":
        findings.extend(_firewall(name, project, merged))
    elif asset_type == "compute.googleapis.com/Instance":
        findings.extend(_instance(name, project, merged))
    elif asset_type == "iam.googleapis.com/ServiceAccountKey":
        findings.extend(_sa_key(name, project, merged))
    elif asset_type == "compute.googleapis.com/Subnetwork":
        findings.extend(_subnet(name, project, merged))

    findings.extend(_labels(name, project, asset_type, asset))
    findings.extend(_location(name, project, asset, allowed))
    return findings


def _bucket(name: str, project: str, data: Mapping[str, object]) -> list[Finding]:
    findings: list[Finding] = []
    iam = data.get("iamConfiguration") if isinstance(data.get("iamConfiguration"), Mapping) else data
    uniform = iam.get("uniformBucketLevelAccess")
    if isinstance(uniform, Mapping):
        uniform_on = bool(uniform.get("enabled"))
    else:
        uniform_on = bool(data.get("uniformBucketLevelAccess") or data.get("uniform_bucket_level_access"))
    pap = str(
        iam.get("publicAccessPrevention")
        or data.get("publicAccessPrevention")
        or data.get("public_access_prevention")
        or ""
    )
    if not uniform_on:
        findings.append(_finding("GCS-001", "high", project, name, "bucket does not use uniform access"))
    if pap.lower() != "enforced":
        findings.append(_finding("GCS-001", "high", project, name, "bucket public access prevention is not enforced"))
    return findings


def _firewall(name: str, project: str, data: Mapping[str, object]) -> list[Finding]:
    if str(data.get("direction") or "INGRESS").upper() != "INGRESS":
        return []
    if data.get("disabled") is True:
        return []
    ranges = [str(item) for item in _as_list(data.get("sourceRanges") or data.get("source_ranges"))]
    if not any(item in WORLD for item in ranges):
        return []
    allows = _as_list(data.get("allowed") or data.get("allow"))
    if not any(_admin_allow(item) for item in allows):
        return []
    return [_finding("FW-001", "high", project, name, "firewall allows admin ports from the internet")]


def _instance(name: str, project: str, data: Mapping[str, object]) -> list[Finding]:
    nics = _as_list(data.get("networkInterfaces") or data.get("network_interfaces"))
    external = False
    for nic in nics:
        if isinstance(nic, Mapping) and _as_list(nic.get("accessConfigs") or nic.get("access_config")):
            external = True
    if not external:
        return []
    return [_finding("VM-001", "high", project, name, "instance has an external IP")]


def _sa_key(name: str, project: str, data: Mapping[str, object]) -> list[Finding]:
    key_type = str(data.get("keyType") or data.get("key_type") or "USER_MANAGED")
    if key_type.upper() != "USER_MANAGED":
        return []
    return [
        _finding(
            "IAM-003",
            "high",
            project,
            name,
            "user-managed service account key exists",
        )
    ]


def _subnet(name: str, project: str, data: Mapping[str, object]) -> list[Finding]:
    log_config = data.get("logConfig") or data.get("log_config")
    enabled = False
    if isinstance(log_config, Mapping):
        enabled = bool(log_config.get("enable") or log_config.get("enabled"))
    if enabled:
        return []
    return [
        _finding(
            "NET-002",
            "medium",
            project,
            name,
            "subnet flow logs are off; no plan-time policy covers this yet",
        )
    ]


def _labels(name: str, project: str, asset_type: str, asset: Mapping[str, object]) -> list[Finding]:
    interesting = {
        "storage.googleapis.com/Bucket",
        "compute.googleapis.com/Instance",
        "bigquery.googleapis.com/Dataset",
    }
    if asset_type not in interesting:
        return []
    labels = asset.get("labels") if isinstance(asset.get("labels"), Mapping) else {}
    missing = [key for key in REQUIRED_LABELS if not str(labels.get(key) or "")]
    if not missing:
        return []
    return [_finding("LBL-001", "medium", project, name, f"missing labels: {', '.join(missing)}")]


def _location(name: str, project: str, asset: Mapping[str, object], allowed: set[str]) -> list[Finding]:
    location = str(asset.get("location") or "")
    if _location_allowed(location, allowed):
        return []
    return [_finding("ORG-012", "medium", project, name, f"location {location} is outside the allow list")]


def _location_allowed(location: str, allowed: set[str]) -> bool:
    if not location:
        return True
    normalized = location.lower()
    if normalized in allowed or normalized in {"global", "unspecified"}:
        return True
    return any(normalized.startswith(f"{item}-") for item in allowed)


def _iam_findings(policy: Mapping[str, object]) -> list[Finding]:
    body = policy.get("policy") if isinstance(policy.get("policy"), Mapping) else {}
    bindings = _as_list(body.get("bindings"))
    asset = str(policy.get("resource") or policy.get("name") or "<iam>")
    project = str(policy.get("project") or "unknown")
    findings: list[Finding] = []
    for binding in bindings:
        if not isinstance(binding, Mapping):
            continue
        role = str(binding.get("role") or "")
        members = [str(item) for item in _as_list(binding.get("members"))]
        if role in PRIMITIVE_ROLES:
            findings.append(_finding("IAM-001", "high", project, asset, f"binding uses {role}"))
        if any(member in PUBLIC_MEMBERS for member in members):
            findings.append(
                _finding("IAM-002", "high", project, asset, "binding grants allUsers or allAuthenticatedUsers")
            )
    return findings


def _finding(catalog_id: str, severity: str, project: str, asset: str, message: str) -> Finding:
    catalog, exists = COVERAGE[catalog_id]
    return Finding(
        rule_id=catalog_id,
        severity=severity,
        project=project,
        asset=asset,
        message=message,
        catalog_id=catalog,
        preventive_exists=exists,
        preventive_gap=not exists,
    )


def _as_list(value: object) -> list[object]:
    if value is None:
        return []
    if isinstance(value, list):
        return value
    return [value]


def _admin_allow(item: object) -> bool:
    if not isinstance(item, Mapping):
        return False
    protocol = str(item.get("IPProtocol") or item.get("ip_protocol") or item.get("protocol") or "").lower()
    ports = [str(port) for port in _as_list(item.get("ports"))]
    if protocol == "all":
        return True
    if protocol != "tcp":
        return False
    if not ports:
        return True
    return any(port in {"22", "3389"} for port in ports)
