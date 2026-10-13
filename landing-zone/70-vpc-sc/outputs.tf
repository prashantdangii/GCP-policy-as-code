output "access_policy" {
  description = "Access policy name, or null when the stack is disabled."
  value       = var.enable_vpc_sc ? google_access_context_manager_access_policy.this[0].name : null
}

output "perimeter" {
  description = "Dry-run perimeter name, or null when the stack is disabled."
  value       = var.enable_vpc_sc ? google_access_context_manager_service_perimeter.data[0].name : null
}

output "mode" {
  description = "Enforcement mode. This stack only proposes a dry-run perimeter."
  value       = var.enable_vpc_sc ? "dry-run" : "disabled"
}
