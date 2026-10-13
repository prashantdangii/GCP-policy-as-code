-- Cost by cost-center and env from a BigQuery billing export.
-- Create the export in the billing console. Replace the table name.
-- BILLING_ACCOUNT_ID is the billing account id with hyphens removed? Keep the
-- export table id exactly as Cloud Billing names it.

SELECT
  invoice.month AS invoice_month,
  currency,
  (
    SELECT value
    FROM UNNEST(labels)
    WHERE key = 'cost-center'
  ) AS cost_center,
  (
    SELECT value
    FROM UNNEST(labels)
    WHERE key = 'env'
  ) AS env,
  ROUND(SUM(cost), 2) AS total_cost
FROM `billing_export.gcp_billing_export_resource_v1_BILLING_ACCOUNT_ID`
WHERE invoice.month >= FORMAT_DATE('%Y%m', DATE_SUB(CURRENT_DATE(), INTERVAL 3 MONTH))
GROUP BY invoice_month, currency, cost_center, env
ORDER BY invoice_month DESC, cost DESC
