"""Command line for the drift scanner.

Offline::

    python -m drift_scanner.cli --input fixtures.json --format md

Live (human or CI with Workload Identity Federation)::

    python -m drift_scanner.cli --scope organizations/ORG_ID --format json
"""

from __future__ import annotations

import argparse
import json
import sys
from collections.abc import Mapping, Sequence
from pathlib import Path

from drift_scanner.report import render
from drift_scanner.rules import Finding, scan


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Scan a GCP scope or a saved asset fixture for drift.")
    parser.add_argument("--scope", default="offline", help="organizations/ID, folders/ID, or projects/ID")
    parser.add_argument("--input", type=Path, help="Offline inventory JSON. Skips Cloud Asset Inventory.")
    parser.add_argument("--format", choices=("json", "html", "md"), default="md")
    parser.add_argument(
        "--allowed-locations",
        default="eu,us,europe-west1,europe-west2,us-central1,us-east1,global",
        help="Comma-separated locations that are not findings.",
    )
    parser.add_argument("--output", type=Path, help="Write the report to this path instead of stdout.")
    args = parser.parse_args(argv)

    try:
        if args.input:
            document = json.loads(args.input.read_text(encoding="utf-8"))
            scope = args.scope
        else:
            document = load_live(args.scope)
            scope = args.scope
    except (OSError, json.JSONDecodeError, RuntimeError) as exc:
        print(f"drift_scanner: {exc}", file=sys.stderr)
        return 2
    if not isinstance(document, dict):
        print("drift_scanner: inventory JSON must be an object", file=sys.stderr)
        return 2

    allowed = [item.strip() for item in args.allowed_locations.split(",") if item.strip()]
    findings = scan(document, allowed)
    body = render(findings, args.format, scope)
    if args.output:
        args.output.write_text(body, encoding="utf-8")
    else:
        sys.stdout.write(body)
    _print_rich_summary(findings)
    return 0


def load_live(scope: str) -> dict[str, object]:
    """Read resources and IAM policies from Cloud Asset Inventory.

    Imported lazily so unit tests never open a network client.
    """

    if not scope.startswith(("organizations/", "folders/", "projects/")):
        raise RuntimeError("live mode needs --scope organizations/ID, folders/ID, or projects/ID")
    try:
        from google.cloud import asset_v1
    except ImportError as exc:
        raise RuntimeError("google-cloud-asset is not installed") from exc

    client = asset_v1.AssetServiceClient()
    resources = [
        _message_dict(item) for item in client.search_all_resources(request={"scope": scope, "page_size": 500})
    ]
    policies = [
        _message_dict(item) for item in client.search_all_iam_policies(request={"scope": scope, "page_size": 500})
    ]
    return {"resources": resources, "iam_policies": policies}


def _message_dict(message: object) -> dict[str, object]:
    if isinstance(message, Mapping):
        return dict(message)
    to_dict = getattr(message, "to_dict", None)
    if callable(to_dict):
        converted = to_dict()
        if isinstance(converted, dict):
            return converted
    return {"name": str(message)}


def _print_rich_summary(findings: list[Finding]) -> None:
    from rich.console import Console

    gaps = sum(1 for item in findings if item.preventive_gap)
    Console(stderr=True).print(f"[bold]drift_scanner[/bold] findings={len(findings)} preventive_gaps={gaps}")


if __name__ == "__main__":
    raise SystemExit(main())
