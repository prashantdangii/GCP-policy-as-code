output "key_id" {
  description = "Crypto key id suitable for CMEK attributes."
  value       = google_kms_crypto_key.this.id
}

output "key_ring_id" {
  description = "Key ring id."
  value       = google_kms_key_ring.this.id
}
