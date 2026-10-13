variable "name" {
  type        = string
  description = "Instance name."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,61}[a-z0-9]$", var.name))
    error_message = "name must be a lowercase Compute instance name."
  }
}

variable "project_id" {
  type        = string
  description = "Project that owns the instance."
}

variable "zone" {
  type        = string
  description = "Zone, for example europe-west1-b."
}

variable "subnetwork" {
  type        = string
  description = "Subnetwork self link or name. The instance has no external address unless allow_external_ip is set."
}

variable "machine_type" {
  type        = string
  description = "Machine type. Very large types are flagged by the advisory FinOps policy."
  default     = "e2-medium"
}

variable "boot_image" {
  type        = string
  description = "Boot image or image family self link."
  default     = "projects/debian-cloud/global/images/family/debian-12"
}

variable "service_account_email" {
  type        = string
  description = "Runtime service account. The default Compute Engine service account is rejected."

  validation {
    condition = (
      length(trimspace(var.service_account_email)) > 0 &&
      !can(regex("^[0-9]+-compute@developer\\.gserviceaccount\\.com$", var.service_account_email))
    )
    error_message = "A non-default service account email is required."
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
  description = "Additional labels."
  default     = {}
}

variable "disk_kms_key" {
  type        = string
  description = "Optional CMEK for the boot disk."
  default     = null
}

variable "tags" {
  type        = list(string)
  description = "Network tags. Include iap-ssh when the instance should accept IAP."
  default     = ["iap-ssh"]
}

variable "allow_external_ip" {
  type        = bool
  description = "Escape hatch that adds an ephemeral external IP."
  default     = false
}

variable "justification" {
  type        = string
  description = "Required when allow_external_ip is true."
  default     = ""

  validation {
    condition     = !var.allow_external_ip || length(trimspace(var.justification)) > 0
    error_message = "justification is required when allow_external_ip is true."
  }
}
