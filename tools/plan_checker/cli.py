"""Command line for plan_checker.

Example::

    python -m plan_checker.cli tfplan.json --format text --fail-on high
"""

from __future__ import annotations

import argparse
import json
import sys
from collections.abc import Sequence
from pathlib import Path

from rich.console import Console
from rich.table import Table

from plan_checker.rules import SEVERITY_RANK, Finding, evaluate, meets_threshold


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Check a terraform show -json plan against guardrails.")
    parser.add_argument("plan", type=Path, help="Path to terraform show -json output")
    parser.add_argument("--format", choices=("text", "json", "sarif"), default="text")
    parser.add_argument("--fail-on", choices=("none", "low", "medium", "high"), default="high")
    args = parser.parse_args(argv)

    try:
        document = json.loads(args.plan.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        print(f"plan_checker: cannot read plan: {exc}", file=sys.stderr)
        return 2
    if not isinstance(document, dict):
        print("plan_checker: plan JSON must be an object", file=sys.stderr)
        return 2

    findings = evaluate(document)
    rendered = render(findings, args.format)
    sys.stdout.write(rendered)
    if rendered and not rendered.endswith("\n"):
        sys.stdout.write("\n")
    return 1 if meets_threshold(findings, args.fail_on) else 0


def render(findings: list[Finding], fmt: str) -> str:
    if fmt == "json":
        return json.dumps([item.to_dict() for item in findings], indent=2)
    if fmt == "sarif":
        return json.dumps(_sarif(findings), indent=2)
    return _text(findings)


def _text(findings: list[Finding]) -> str:
    if not findings:
        return "plan_checker: no findings\n"
    lines = []
    table = Table(title="plan_checker")
    table.add_column("Severity")
    table.add_column("Rule")
    table.add_column("Resource")
    table.add_column("Message")
    for finding in findings:
        lines.append(f"{finding.severity.upper():6} {finding.rule_id:10} {finding.resource_address}: {finding.message}")
        lines.append(f"       fix: {finding.remediation}")
        table.add_row(finding.severity, finding.rule_id, finding.resource_address, finding.message)
    Console(stderr=True).print(table)
    return "\n".join(lines) + "\n"


def _sarif(findings: list[Finding]) -> dict[str, object]:
    rules = {}
    results = []
    for finding in findings:
        rules.setdefault(
            finding.rule_id,
            {
                "id": finding.rule_id,
                "shortDescription": {"text": finding.message},
                "help": {"text": finding.remediation},
                "properties": {"security-severity": str(SEVERITY_RANK[finding.severity])},
            },
        )
        results.append(
            {
                "ruleId": finding.rule_id,
                "level": "error" if finding.severity == "high" else "warning",
                "message": {"text": f"{finding.resource_address}: {finding.message}"},
                "locations": [
                    {
                        "physicalLocation": {
                            "artifactLocation": {"uri": "tfplan.json"},
                            "region": {"startLine": 1},
                        }
                    }
                ],
            }
        )
    return {
        "version": "2.1.0",
        "$schema": "https://json.schemastore.org/sarif-2.1.0.json",
        "runs": [
            {
                "tool": {"driver": {"name": "plan_checker", "rules": list(rules.values())}},
                "results": results,
            }
        ],
    }


if __name__ == "__main__":
    raise SystemExit(main())
