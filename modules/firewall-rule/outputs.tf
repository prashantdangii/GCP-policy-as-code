output "name" {
  description = "Firewall rule name."
  value       = google_compute_firewall.this.name
}

output "self_link" {
  description = "Firewall rule self link."
  value       = google_compute_firewall.this.self_link
}
