variable "scope_type" {
  type        = string
  description = "organization, folder, or project. Selects the aggregated sink and audit-config resource."

  validation {
    condition     = contains(["organization", "folder", "project"], var.scope_type)
    error_message = "scope_type must be organization, folder, or project."
  }
}

variable "scope_id" {
  type        = string
  description = "Raw organization, folder, or project id the sink is attached to."
}

variable "logging_project_id" {
  type        = string
  description = "logging-hub project that stores the BigQuery dataset and archive bucket."
}

variable "region" {
  type        = string
  description = "Provider region."
  default     = "europe-west1"
}

variable "dataset_location" {
  type        = string
  description = "BigQuery dataset location."
  default     = "EU"
}

variable "bucket_location" {
  type        = string
  description = "Archive bucket location."
  default     = "eu"
}

variable "audit_dataset_id" {
  type        = string
  description = "BigQuery dataset id for the audit export."
  default     = "audit_logs"
}

variable "archive_bucket_name" {
  type        = string
  description = "Globally unique archive bucket name. Example: PROJECT_PREFIX-audit-archive."
}

variable "default_table_expiration_ms" {
  type        = number
  description = "Default BigQuery table lifetime. 365 days by default. Shorten it to cut storage cost."
  default     = 31536000000
}

variable "retention_period_seconds" {
  type        = number
  description = "GCS retention period for the archive. 365 days by default."
  default     = 31536000
}

variable "lock_retention" {
  type        = bool
  description = "Lock the archive retention policy. Irreversible. Default false."
  default     = false
}

variable "kms_key_name" {
  type        = string
  description = "Optional CMEK for the dataset and archive bucket."
  default     = null
}

variable "audit_exempted_members" {
  type        = list(string)
  description = "Members exempted from DATA_READ and DATA_WRITE audit logs. Use this to cut cost, and record why."
  default     = []
}

variable "log_bucket_retention_days" {
  type        = number
  description = "Retention on the project _Default log bucket. This is separate from the archive bucket."
  default     = 30
}

variable "exclusion_filters" {
  type = list(object({
    name        = string
    filter      = string
    description = string
  }))
  description = "Sink exclusions. Every exclusion trades visibility for cost. Leave empty until you have a measured reason."
  default     = []
}
