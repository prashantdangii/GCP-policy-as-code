output "dataset_id" {
  description = "Dataset id."
  value       = google_bigquery_dataset.this.dataset_id
}

output "self_link" {
  description = "Dataset self link."
  value       = google_bigquery_dataset.this.self_link
}
