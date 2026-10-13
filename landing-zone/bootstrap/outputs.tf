output "state_bucket" {
  description = "GCS bucket that stores Terraform state."
  value       = google_storage_bucket.state.name
}

output "ci_service_account" {
  description = "Email of the keyless CI service account."
  value       = google_service_account.ci.email
}

output "workload_identity_provider" {
  description = "Full provider resource name for google-github-actions/auth."
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "github_repository" {
  description = "Repository the pool provider will accept."
  value       = var.github_repository
}
