variable "name" {
  type        = string
  description = "Globally unique bucket name."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9._-]{1,61}[a-z0-9]$", var.name))
    error_message = "name must be a valid GCS bucket name."
  }
}

variable "project_id" {
  type        = string
  description = "Project that owns the bucket."
}

variable "allowed_locations" {
  type        = list(string)
  description = "Locations the bucket may use. Align this with the gcp.resourceLocations org policy."
  default     = ["eu", "us", "europe-west1", "europe-west2", "us-central1", "us-east1"]
}

variable "location" {
  type        = string
  description = "Bucket location. Must be in allowed_locations."

  validation {
    condition     = contains(var.allowed_locations, var.location)
    error_message = "location is not in allowed_locations."
  }
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
  description = "Additional labels merged on top of the required set."
  default     = {}
}

variable "kms_key_name" {
  type        = string
  description = "Optional CMEK. Null uses Google-managed encryption. The advisory CMEK policy warns when this is null."
  default     = null
}

variable "log_bucket" {
  type        = string
  description = "Optional bucket that receives access logs."
  default     = null
}

variable "retention_seconds" {
  type        = number
  description = "Optional retention period in seconds."
  default     = null
}

variable "lock_retention" {
  type        = bool
  description = "Lock the retention policy. Irreversible. Requires retention_seconds."
  default     = false

  validation {
    condition     = !var.lock_retention || (var.retention_seconds != null && var.retention_seconds >= 1)
    error_message = "retention_seconds must be set before lock_retention."
  }
}

variable "force_destroy" {
  type        = bool
  description = "Allow destroy of a non-empty bucket. Default false."
  default     = false
}

variable "allow_public_access" {
  type        = bool
  description = "Escape hatch. When true, public access prevention is inherited instead of enforced."
  default     = false
}

variable "justification" {
  type        = string
  description = "Required non-empty string when allow_public_access is true."
  default     = ""

  validation {
    condition     = !var.allow_public_access || length(trimspace(var.justification)) > 0
    error_message = "justification is required when allow_public_access is true."
  }
}
