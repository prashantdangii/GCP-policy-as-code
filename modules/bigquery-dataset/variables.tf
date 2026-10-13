variable "dataset_id" {
  type        = string
  description = "Dataset id."

  validation {
    condition     = can(regex("^[A-Za-z0-9_]+$", var.dataset_id))
    error_message = "dataset_id must contain only letters, numbers, and underscores."
  }
}

variable "project_id" {
  type        = string
  description = "Project that owns the dataset."
}

variable "location" {
  type        = string
  description = "Dataset location."
  default     = "EU"
}

variable "labels" {
  type        = map(string)
  description = "Required labels: owner, env, cost-center. env must be prod, nonprod, or shared."

  validation {
    condition = (
      alltrue([for key in ["owner", "env", "cost-center"] : contains(keys(var.labels), key)]) &&
      contains(["prod", "nonprod", "shared"], lookup(var.labels, "env", "")) &&
      can(regex("^[a-z0-9_-]{1,63}$", lookup(var.labels, "owner", ""))) &&
      can(regex("^[a-z0-9_-]{1,63}$", lookup(var.labels, "cost-center", "")))
    )
    error_message = "labels must include lowercase owner and cost-center, and env of prod, nonprod, or shared."
  }
}

variable "extra_labels" {
  type        = map(string)
  description = "Additional labels."
  default     = {}
}

variable "kms_key_name" {
  type        = string
  description = "Optional CMEK for the dataset."
  default     = null
}

variable "default_table_expiration_ms" {
  type        = number
  description = "Optional default table lifetime in milliseconds."
  default     = null
}

variable "authorized_groups" {
  type        = map(string)
  description = "Map of group email to BigQuery role. allUsers and allAuthenticatedUsers are rejected."
  default     = {}

  validation {
    condition = alltrue([
      for email, role in var.authorized_groups :
      !contains(["allUsers", "allAuthenticatedUsers"], email) &&
      can(regex("^group:[^@]+@[^@]+$", "group:${email}")) &&
      length(trimspace(role)) > 0
    ])
    error_message = "authorized_groups must be real group emails, never allUsers or allAuthenticatedUsers."
  }
}

variable "delete_contents_on_destroy" {
  type        = bool
  description = "Delete tables on destroy. Default false."
  default     = false
}
