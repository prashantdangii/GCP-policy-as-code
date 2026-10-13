output "name" {
  description = "Instance name."
  value       = google_compute_instance.this.name
}

output "self_link" {
  description = "Instance self link."
  value       = google_compute_instance.this.self_link
}

output "service_account_email" {
  description = "Runtime service account."
  value       = var.service_account_email
}
