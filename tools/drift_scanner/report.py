"""Render drift findings as JSON, Markdown, or HTML."""

from __future__ import annotations

import json
from collections import Counter
from datetime import UTC, datetime

from drift_scanner.rules import Finding


def render(findings: list[Finding], fmt: str, scope: str) -> str:
    generated = datetime.now(UTC).replace(microsecond=0).isoformat()
    if fmt == "json":
        return json.dumps(
            {
                "generated_at": generated,
                "scope": scope,
                "summary": _summary(findings),
                "findings": [item.to_dict() for item in findings],
            },
            indent=2,
        )
    if fmt == "html":
        return _html(findings, scope, generated)
    return _markdown(findings, scope, generated)


def _summary(findings: list[Finding]) -> dict[str, object]:
    by_severity = Counter(item.severity for item in findings)
    by_project = Counter(item.project for item in findings)
    return {
        "total": len(findings),
        "by_severity": dict(by_severity),
        "preventive_gaps": sum(1 for item in findings if item.preventive_gap),
        "top_projects": by_project.most_common(5),
    }


def _markdown(findings: list[Finding], scope: str, generated: str) -> str:
    summary = _summary(findings)
    lines = [
        "# Drift report",
        "",
        f"- Generated: `{generated}`",
        f"- Scope: `{scope}`",
        f"- Findings: {summary['total']}",
        f"- Preventive gaps: {summary['preventive_gaps']}",
        "",
        "## By severity",
        "",
    ]
    by_severity = summary["by_severity"]
    assert isinstance(by_severity, dict)
    if not by_severity:
        lines.append("No findings.")
    for severity, count in sorted(by_severity.items()):
        lines.append(f"- {severity}: {count}")
    lines.extend(["", "## Top projects", ""])
    top = summary["top_projects"]
    assert isinstance(top, list)
    if not top:
        lines.append("None.")
    for project, count in top:
        lines.append(f"- {project}: {count}")
    lines.extend(["", "## Findings", ""])
    if not findings:
        lines.append("None.")
    for finding in findings:
        gap = " preventive gap" if finding.preventive_gap else ""
        lines.append(
            f"- **{finding.severity}** `{finding.catalog_id}` {finding.asset} ({finding.project}): {finding.message}.{gap}"
        )
    lines.append("")
    return "\n".join(lines)


def _html(findings: list[Finding], scope: str, generated: str) -> str:
    summary = _summary(findings)
    rows = "\n".join(
        "<tr><td>{sev}</td><td>{catalog}</td><td>{project}</td><td>{asset}</td><td>{message}</td><td>{gap}</td></tr>".format(
            sev=_escape(finding.severity),
            catalog=_escape(finding.catalog_id),
            project=_escape(finding.project),
            asset=_escape(finding.asset),
            message=_escape(finding.message),
            gap="yes" if finding.preventive_gap else "no",
        )
        for finding in findings
    )
    return f"""<!DOCTYPE html>
<html lang="en">
<head><meta charset="utf-8"><title>Drift report</title></head>
<body>
<h1>Drift report</h1>
<p>Generated {_escape(generated)} for {_escape(scope)}.</p>
<p>{summary["total"]} findings, {summary["preventive_gaps"]} preventive gaps.</p>
<table>
<thead><tr><th>Severity</th><th>Control</th><th>Project</th><th>Asset</th><th>Message</th><th>Preventive gap</th></tr></thead>
<tbody>
{rows}
</tbody>
</table>
</body>
</html>
"""


def _escape(value: str) -> str:
    return value.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace('"', "&quot;")
