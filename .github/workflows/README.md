# Workflows

| File | When | What |
|---|---|---|
| `ci.yml` | Pull request | fmt, tflint, ruff, gitleaks, validate, Checkov, Trivy, Sentinel, OPA, pytest, terraform test, optional WIF plan, offline policy demo |
| `apply.yml` | Push to `main`, or manual | Re-plan, Conftest, plan_checker, apply. Skips until WIF variables and the `production` environment are set |
| `drift.yml` | Mondays 06:00 UTC, or manual | Live drift scan via WIF. Uploads JSON and HTML. Opens or updates a GitHub issue when findings exist |

Pinned tool versions match `docs/HANDOFF.md`.
