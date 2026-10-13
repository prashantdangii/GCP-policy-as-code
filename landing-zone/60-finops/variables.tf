variable "project_id" {
  type        = string
  description = "Project that owns the budget Pub/Sub topic. Often sec-tooling or logging-hub."
}

variable "project_number" {
  type        = string
  description = "Project number used to grant the Cloud Billing service agent publish rights."
}

variable "region" {
  type        = string
  description = "Provider region."
  default     = "europe-west1"
}

variable "billing_account_id" {
  type        = string
  description = "Billing account id. Placeholder: BILLING_ACCOUNT_ID."
}

variable "budget_amount" {
  type        = number
  description = "Monthly budget in currency units."
  default     = 100
}

variable "currency_code" {
  type        = string
  description = "ISO currency code."
  default     = "USD"
}

variable "monitored_projects" {
  type        = list(string)
  description = "Optional projects filter, each as projects/PROJECT_ID. Empty watches the whole billing account."
  default     = []
}

variable "notification_channel_id" {
  type        = string
  description = "Optional monitoring notification channel from 50-monitoring."
  default     = null
}
