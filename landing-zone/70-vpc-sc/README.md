# 70-vpc-sc

Optional VPC Service Controls perimeter around `data-sample`. **Off by default** (`enable_vpc_sc = false`). When enabled, the perimeter is **dry-run only**: `use_explicit_dry_run_spec = true` and there is no `status` block, so nothing is blocked.

Restricted services in the dry-run spec: `storage.googleapis.com` and `bigquery.googleapis.com`.

## Ingress and egress examples

The dry-run spec includes:

- Ingress from the `corp_ip` access level (default `203.0.113.0/24`, which is the documentation range TEST-NET-3) to Storage.
- Egress for one sample runtime service account to BigQuery. Replace that identity before you promote the perimeter out of dry-run.

Replace `203.0.113.0/24` with your corporate egress ranges. Do not leave the documentation range in place if you later copy `spec` into `status`.

## How this differs from firewall rules

Firewall rules in `20-network` decide which packets may flow. VPC Service Controls decide which API calls may cross a project boundary, including calls from laptops and other VPCs that never touch `shared-vpc`. A public IP block does not stop an identity in another project from calling the Storage API. A perimeter does.

## Promotion

Read dry-run violations in Cloud Logging (the `50-monitoring` metric `vpc_sc_violations`) before you add a `status` block. Promotion is a human change. This module will not enforce the perimeter for you.
