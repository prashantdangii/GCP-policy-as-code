# 50-monitoring

Six log-based metrics and matching alert policies in the logging hub. Metrics only see logs that have been exported into, or written in, that project. Point this stack at `logging-hub` after `30-logging` is applied.

| Metric | What it counts |
| --- | --- |
| `iam-policy-changes` | `SetIamPolicy` |
| `firewall-changes` | Firewall insert, patch, delete |
| `sa-key-creation` | `CreateServiceAccountKey` |
| `org-policy-changes` | Org Policy create, update, delete |
| `vpc-sc-violations` | VPC-SC audit metadata |
| `logging-config-changes` | Sink and exclusion updates, including a sink being disabled |

Alerts fire when the count in a minute is greater than zero and email `notification_email`.

## Availability note

The sample application is not a separate MIG in this repo, because a regional managed instance group would be a paid resource the human applies later. The network is already multi-subnet and regional. A highly available sample would be a regional MIG on `prod-subnet` and `nonprod-subnet` across `europe-west1-b` and `europe-west1-c`, with the health-check firewall tag `lb-backend` and no external IPs. That pattern uses the same `compute-instance` security defaults (no public IP, Shielded VM, custom service account) on the instance template.
