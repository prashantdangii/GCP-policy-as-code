# 60-finops

A billing budget at 50%, 80%, and 100% of `budget_amount`. Notifications go to Pub/Sub topic `billing-budget-alerts` and, when set, to the monitoring channel from `50-monitoring`.

The Cloud Billing service agent `service-PROJECT_NUMBER@gcp-sa-billing-budgets.iam.gserviceaccount.com` is granted `roles/pubsub.publisher` on that topic. Pass the project number; this stack does not call a data source.

Cost allocation uses the required `cost-center` and `env` labels enforced by Sentinel and OPA. The query that groups the billing export is `queries/bigquery/billing_by_label.sql`. The export dataset itself is created in the Cloud Billing console, not here, because the billing export API is not fully manageable from this provider without an existing export.

See `docs/finops.md` for the control-to-cost table.
