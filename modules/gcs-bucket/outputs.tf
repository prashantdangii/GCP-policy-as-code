output "name" {
  description = "Bucket name."
  value       = google_storage_bucket.this.name
}

output "url" {
  description = "gs:// URL."
  value       = google_storage_bucket.this.url
}

output "public_access_prevention" {
  description = "Effective public access prevention mode."
  value       = google_storage_bucket.this.public_access_prevention
}
