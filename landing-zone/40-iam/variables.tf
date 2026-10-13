variable "region" {
  type        = string
  description = "Provider region."
  default     = "europe-west1"
}

variable "scope_type" {
  type        = string
  description = "organization, folder, or project. Custom roles and bindings follow this scope."

  validation {
    condition     = contains(["organization", "project"], var.scope_type)
    error_message = "scope_type must be organization or project. IAM custom roles cannot be created on a folder."
  }
}

variable "scope_id" {
  type        = string
  description = "Raw organization, folder, or project id."
}

variable "security_project_id" {
  type        = string
  description = "Project where the time-bound deployer binding is applied. Use sec-tooling, or the lab project."
}

variable "security_group" {
  type        = string
  description = "Google group for security viewers, without the group: prefix."
  default     = "grp-security@example.com"
}

variable "deployer_group" {
  type        = string
  description = "Google group for time-bound deployers, without the group: prefix."
  default     = "grp-deployers@example.com"
}

variable "break_glass_principal" {
  type        = string
  description = "Principal exempt from the IAM deny policy. Use a group, not a person."
  default     = "principalSet://goog/group/grp-break-glass@example.com"
}

variable "deployer_access_until" {
  type        = string
  description = "RFC3339 timestamp after which the deployer binding stops working."
  default     = "2027-01-01T00:00:00Z"

  validation {
    condition     = can(regex("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$", var.deployer_access_until))
    error_message = "deployer_access_until must be an RFC3339 UTC timestamp."
  }
}
