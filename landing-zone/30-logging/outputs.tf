output "dataset_id" {
  description = "BigQuery dataset that receives the audit export."
  value       = google_bigquery_dataset.audit.dataset_id
}

output "archive_bucket" {
  description = "GCS archive bucket."
  value       = google_storage_bucket.archive.name
}

output "writer_identity" {
  description = "Sink writer granted dataEditor on the dataset."
  value       = local.writer_identity
}
