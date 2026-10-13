output "security_viewer_role" {
  description = "Custom security viewer role name."
  value       = local.viewer_role
}

output "deployer_role" {
  description = "Custom deployer role name."
  value       = local.deployer_role
}

output "deny_policy" {
  description = "Deny policy name."
  value       = google_iam_deny_policy.sensitive.name
}
