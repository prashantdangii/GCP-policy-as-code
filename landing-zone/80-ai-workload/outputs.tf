output "runtime_service_account" {
  description = "Vertex runtime service account, or null when the stack is disabled."
  value       = var.enable_ai_workload ? google_service_account.runtime[0].email : null
}

output "endpoint" {
  description = "Sample endpoint id, or null when the stack is disabled."
  value       = var.enable_ai_workload ? google_vertex_ai_endpoint.sample[0].id : null
}

output "kms_key_name" {
  description = "Optional CMEK the human should attach when the Vertex product supports it."
  value       = var.kms_key_name
}
