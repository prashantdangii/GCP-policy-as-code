output "network_id" {
  description = "Shared VPC id."
  value       = google_compute_network.shared.id
}

output "network_name" {
  description = "Shared VPC name."
  value       = google_compute_network.shared.name
}

output "subnet_ids" {
  description = "Environment name to subnet id."
  value       = { for key, subnet in google_compute_subnetwork.env : key => subnet.id }
}

output "nat_name" {
  description = "Cloud NAT name."
  value       = google_compute_router_nat.nat.name
}
