-- Firewall create, patch, or delete events whose payload mentions 0.0.0.0/0.
-- Replace audit_logs with the dataset from landing-zone/30-logging.

SELECT
  timestamp,
  protopayload_auditlog.authenticationinfo.principalemail AS principal,
  protopayload_auditlog.methodname AS method_name,
  protopayload_auditlog.resourcename AS resource_name
FROM `audit_logs.clou_googleapis_com_activity`
WHERE
  timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
  AND protopayload_auditlog.servicename = 'compute.googleapis.com'
  AND REGEXP_CONTAINS(
    protopayload_auditlog.methodname,
    r'firewalls\.(insert|patch|delete|update)'
  )
  AND REGEXP_CONTAINS(TO_JSON_STRING(protopayload_auditlog), r'0\.0\.0\.0/0')
ORDER BY timestamp DESC
