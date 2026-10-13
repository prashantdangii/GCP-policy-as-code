# Handoff

Built and checked on this machine. Not applied to GCP. Not pushed.

## Offline demo

```bash
make test
make policy-demo
make drift
```

`make test` runs Sentinel, OPA, pytest, and `terraform test`. The first Terraform test in a fresh clone downloads the Google provider. `make policy-demo` needs `conftest` and the Python packages in `tools/requirements.txt`. It must print no findings for `examples/compliant/plan.json` and the seven control ids for `examples/non-compliant/plan.json`.

## Still yours

Listed in `docs/runbook.md`: organization or project, billing, `gcloud auth application-default login`, `terraform apply`, GitHub variables, the `production` environment reviewers, branch protection, optional HCP Terraform, screenshots.

Suggested shots:

- A pull request whose `example-policy-demo` job fails on `open_ssh.tf` / FW-001.
- A pull request that only touches `examples/compliant` and goes green.
- `make drift` markdown showing IAM-003 with preventive coverage and NET-002 as a preventive gap.

## Limitations

Same list as `docs/interview-notes.md`. The important ones: Sentinel is tested, not enforced, in GitHub. CMEK and VPC-SC are deliberately not hard. No live API calls were made, including Cloud Asset Inventory.

## Versions that were installed here

Terraform 1.16.5, Google provider 8.6.0, Sentinel 0.41.0, OPA 1.21.2, Conftest 0.71.1, TFLint 0.64.0, gitleaks 8.30.1, Trivy 0.75.0, Checkov 3.3.28, sqlfluff 4.4.0, Python 3.14 locally and 3.11 in CI.
