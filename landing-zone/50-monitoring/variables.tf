variable "logging_project_id" {
  type        = string
  description = "Project where the aggregated logs land. Log-based metrics only see logs in this project."
}

variable "region" {
  type        = string
  description = "Provider region."
  default     = "europe-west1"
}

variable "notification_email" {
  type        = string
  description = "Email address for the monitoring notification channel."
  default     = "security-alerts@example.com"
}
