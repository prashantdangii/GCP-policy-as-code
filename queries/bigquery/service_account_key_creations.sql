-- Service-account key creations by principal.
-- Replace audit_logs with the dataset from landing-zone/30-logging.

SELECT
  protopayload_auditlog.authenticationinfo.principalemail AS principal,
  COUNT(*) AS key_creations
FROM `audit_logs.clou_googleapis_com_activity`
WHERE
  timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 DAY)
  AND protopayload_auditlog.methodname = 'google.iam.admin.v1.CreateServiceAccountKey'
GROUP BY principal
ORDER BY key_creations DESC
