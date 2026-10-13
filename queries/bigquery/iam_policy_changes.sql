-- Who changed an IAM policy in the last 7 days.
-- Replace audit_logs with the dataset from landing-zone/30-logging.

SELECT
  timestamp,
  protopayload_auditlog.authenticationinfo.principalemail AS principal,
  protopayload_auditlog.methodname AS method_name,
  protopayload_auditlog.resourcename AS resource_name,
  resource.labels.project_id AS gcp_project_id
FROM `audit_logs.clou_googleapis_com_activity`
WHERE
  timestamp >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
  AND ENDS_WITH(protopayload_auditlog.methodname, 'SetIamPolicy')
ORDER BY timestamp DESC
