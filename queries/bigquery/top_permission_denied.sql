-- Top PERMISSION_DENIED calls by principal and method.
-- status.code 7 is PERMISSION_DENIED.
-- Replace audit_logs with the dataset from landing-zone/30-logging.

SELECT
  protopayload_auditlog.authenticationinfo.principalemail AS principal,
  protopayload_auditlog.methodname AS method_name,
  COUNT(*) AS denied_calls
FROM `audit_logs.clou_googleapis_com_activity`
WHERE
  timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
  AND protopayload_auditlog.status.code = 7
GROUP BY principal, method_name
ORDER BY denied_calls DESC
LIMIT 50
