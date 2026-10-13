output "budget_topic" {
  description = "Pub/Sub topic that receives budget notifications."
  value       = google_pubsub_topic.budget.id
}

output "budget_display_name" {
  description = "Budget display name."
  value       = google_billing_budget.landing_zone.display_name
}
