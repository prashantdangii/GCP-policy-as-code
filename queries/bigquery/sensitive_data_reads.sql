-- Data Access reads on the sample dataset by principals outside the analyst group.
-- Replace audit_logs and the dataset resource name before use.
-- This query is a starting point. Tune the allow list to the groups that should read the data.

SELECT
  timestamp,
  protopayload_auditlog.authenticationinfo.principalemail AS principal,
  protopayload_auditlog.methodname AS method_name,
  protopayload_auditlog.resourcename AS resource_name
FROM `audit_logs.clou_googleapis_com_data_access`
WHERE
  timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
  AND protopayload_auditlog.servicename = 'bigquery.googleapis.com'
  AND REGEXP_CONTAINS(protopayload_auditlog.resourcename, r'datasets/app_analytics')
  AND NOT ENDS_WITH(
    protopayload_auditlog.authenticationinfo.principalemail,
    '@example.com'
  )
ORDER BY timestamp DESC
