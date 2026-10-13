-- Organization Policy changes over time.
-- Replace audit_logs with the dataset from landing-zone/30-logging.

SELECT
  protopayload_auditlog.authenticationinfo.principalemail AS principal,
  protopayload_auditlog.methodname AS method_name,
  protopayload_auditlog.resourcename AS resource_name,
  TIMESTAMP_TRUNC(timestamp, DAY) AS change_day,
  COUNT(*) AS change_count
FROM `audit_logs.clou_googleapis_com_activity`
WHERE
  timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)
  AND protopayload_auditlog.servicename = 'orgpolicy.googleapis.com'
GROUP BY principal, method_name, resource_name, change_day
ORDER BY change_day DESC
