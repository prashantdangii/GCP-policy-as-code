# BigQuery queries

| File | Question |
|---|---|
| `iam_policy_changes.sql` | Who changed IAM in the last 7 days |
| `firewall_world_ingress.sql` | Firewall changes that mention `0.0.0.0/0` |
| `service_account_key_creations.sql` | Key creations by principal |
| `top_permission_denied.sql` | Top denied calls |
| `sensitive_data_reads.sql` | Data Access reads on `app_analytics` by unusual principals |
| `org_policy_changes.sql` | Org Policy changes by day |
| `billing_by_label.sql` | Cost grouped by `cost-center` and `env` |

Admin Activity logs are on by default. Data Access logs exist only after `landing-zone/30-logging` enables them, so `sensitive_data_reads.sql` stays empty until that stack is applied.
