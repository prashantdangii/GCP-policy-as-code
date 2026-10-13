output "notification_channel" {
  description = "Email notification channel id. Pass this to the FinOps budget if you want the same inbox."
  value       = google_monitoring_notification_channel.email.id
}

output "metric_names" {
  description = "Log-based metric names."
  value       = keys(google_logging_metric.security)
}
