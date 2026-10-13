variable "project_id" {
  type        = string
  description = "Project that owns the service account."
}

variable "account_id" {
  type        = string
  description = "Account id, not the email. 6-30 characters."

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.account_id))
    error_message = "account_id must be 6-30 lowercase characters."
  }
}

variable "display_name" {
  type        = string
  description = "Console display name."
}

variable "description" {
  type        = string
  description = "What this identity is allowed to do."

  validation {
    condition     = length(trimspace(var.description)) > 0
    error_message = "description is required so the account is not an unnamed credential."
  }
}

variable "wif_member" {
  type        = string
  description = "Optional Workload Identity principal granted roles/iam.workloadIdentityUser. Null creates no binding and no key."
  default     = null
}
