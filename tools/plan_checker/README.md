# plan_checker

Reads `terraform show -json`. Ignores deletes and no-ops. Emits findings with a control id, severity, address, and remediation. Unknown attributes become `UNVERIFIED` at low severity. `--fail-on` defaults to `high`. Formats: `text`, `json`, `sarif`.
