# Interview notes

Thirty seconds each. The paths are the evidence. Nothing here was applied to a live GCP organization.

| JD theme | Show this | Talking point |
|---|---|---|
| IAM | `landing-zone/40-iam`, IAM-001, IAM-006 | Groups, two custom roles, one time-bound condition, one deny policy. No owner or editor in the landing zone. |
| VPC | `landing-zone/20-network`, `modules/firewall-rule` | Custom-mode Shared VPC, Private Google Access, flow logs, deny-all ingress, IAP for admin, NAT. Firewall rules are not VPC-SC. |
| Logging | `landing-zone/30-logging`, `queries/bigquery` | Admin Activity is already on. Data Access is explicit because it costs money. Six SQL detections. |
| KMS and storage | `modules/kms-key`, `modules/gcs-bucket`, CMEK-001 | Uniform access and public access prevention are hard. CMEK is advisory because the key has to exist first. |
| Org Policy | `landing-zone/00-org-policies`, ADR 0004 | Twelve constraints, scope is org, folder, or project, exceptions need a reason and a date. |
| VPC Service Controls | `landing-zone/70-vpc-sc`, `docs/architecture.md` | Dry-run perimeter around storage and BigQuery. It constrains APIs and identities. Firewalls constrain packets. |
| Terraform modules and state | `modules/`, `landing-zone/bootstrap` | Secure defaults with validation blocks. State bucket is locked down. First apply is local, then the GCS backend. |
| CI | `.github/workflows/ci.yml`, ADR 0003 | WIF, no JSON keys. Plan skips until variables exist. The offline demo still fails the bad example. |
| Sentinel | `policies/sentinel`, ADR 0002 | `tfplan/v2`, enforcement levels, mocks, tests. `sentinel test` is green. Native enforcement needs HCP Terraform. |
| OPA | `policies/opa`, `docs/sentinel-vs-opa.md` | Rego v1, Conftest is the free CI gate. I would pick OPA for multi-cloud and Sentinel for a Terraform Enterprise shop. |
| Preventive vs detective | ADR 0005, `tools/drift_scanner` | Plan checks block the next apply. The scanner reads live assets. Gaps become the next policy. |
| Control feasibility | `docs/policy-catalog.md` | Presence of a label is automatable. Whether the classification is true is not. Banning Editor is automatable. Proving least privilege is appropriate is not. |
| CNAPP loop | ADR 0005 | User-managed keys were a finding. They are now an org policy plus `no-sa-keys`. Flow logs are still a gap. |
| Blocked deploy | `docs/troubleshooting-blocked-deployments.md`, `examples/non-compliant/open_ssh.tf` | Reproduce with the plan JSON, name FW-001, fix with the IAP range, add a test. |
| FinOps | `docs/finops.md`, `landing-zone/60-finops` | Labels for allocation, budget thresholds, and a table of which security choice drives which line item. |
| Python | `tools/plan_checker`, `tools/drift_scanner` | Typed rules, fixtures, coverage above 90% on the rule modules. Offline mode does not import the Google client. |
| Logging queries | `queries/bigquery`, architecture "Logging and query practice" | Filter, aggregate, time window. SQL here, XQL as the same shape in another product. |
| Stakeholder docs | `docs/rollout-strategy.md`, `docs/finops.md` | Levels, promotion numbers, exception expiry, cost in words a budget owner can use. |
| Agentic AI | `docs/threat-model-agentic-ai.md`, `landing-zone/80-ai-workload` | Least-privilege runtime, no keys, egress allow list, indirect prompt injection described without payloads. |

## Known limitations

- Sentinel does not block GitHub merges. Conftest and plan_checker do. HCP Terraform would be required for native Sentinel enforcement.
- Scale is one org or one project on paper. The rollout doc says how the same policy set would be pinned for 500 projects. That layout was not built.
- No stack was applied. Validate and plan fixtures are not a substitute for a real apply.
- CMEK is advisory. VPC-SC is dry-run and off. The AI endpoint is off.
- NET-002 has no plan-time policy yet.
- Checkov CKV_GCP_125 is skipped because a `sub` equality check would reject real pull-request tokens. ADR 0003.

## Scaling to 500 projects

Pin the policy bundle by semver. Attach org policies at the organization and keep exceptions on folders with an expiry. Run Conftest in each team's pipeline against the same tag. Run drift per folder on a schedule. Keep one CI service account per environment, still via WIF, still without keys. Split state by stack, which this repo already does, not one state for 500 projects.
