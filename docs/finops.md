# FinOps

Security controls spend money. The point of this page is to say where, and what to turn down before the invoice arrives.

## Tagging

Every project and every golden-module resource carries `owner`, `env`, and `cost-center`. `env` is `prod`, `nonprod`, or `shared`. LBL-001 enforces presence. The billing export query `queries/bigquery/billing_by_label.sql` groups the detailed export by those two labels. Create the export in the Cloud Billing console. Terraform in `landing-zone/60-finops` creates the budget, not the export.

Budgets alert at 50%, 80%, and 100% of `var.budget_amount` through Pub/Sub and an optional email channel.

## Control, cost, mitigation

| Control | Cost driver | Mitigation |
|---|---|---|
| Data Access audit logs (LOG-002) | One row per read and write. BigQuery and GCS data plane logs dominate | Exclude high-volume methods. Exempt break-glass automation accounts via `audit_exempted_members`. Keep Admin Activity, which is free of this choice because it is always on |
| Log retention (LOG-001) | BigQuery storage and the archive bucket | `default_table_expiration` and bucket retention are variables. Lock retention only when a compliance rule requires it |
| Cloud NAT and restricted egress (NET-005) | NAT gateway hours and egress processing | One NAT per region in the hub. Do not add per-project NATs. Open egress only for ranges you can name |
| CMEK (CMEK-001) | KMS operations per read/write, and a key ring per location | Advisory until a dataset is actually sensitive. One key per data class, not one key per bucket |
| Flow logs (NET-002) | Logging volume grows with sampling and with metadata | Default sampling is 0.5. Drop metadata to `EXCLUDE_ALL_METADATA` on chatty subnets. Do not turn the logs off. That is the open preventive gap |
| Security Command Center | Standard versus Premium SKU | This repo does not enable SCC. Premium is a paid detective layer that overlaps the drift scanner. Buy it when the org is real, and keep the plan-time gates either way |
| Large machines (FIN-001) | vCPU and RAM | Advisory policy plus the budget. The policy does not cap quota |

## What this repo does not bill

No apply was run. The table is the estimate a reviewer should use before they do. Teardown is in `docs/runbook.md`.
