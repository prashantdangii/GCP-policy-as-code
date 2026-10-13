variable "region" {
  type        = string
  description = "Provider region."
  default     = "europe-west1"
}

variable "scope_type" {
  type        = string
  description = "organization or folder creates the folder tree. project skips folders and reuses scope_id for every logical project."

  validation {
    condition     = contains(["organization", "folder", "project"], var.scope_type)
    error_message = "scope_type must be organization, folder, or project."
  }
}

variable "scope_id" {
  type        = string
  description = "Organization id, parent folder id, or the single lab project id."

  validation {
    condition     = length(trimspace(var.scope_id)) > 0 && !strcontains(var.scope_id, "/")
    error_message = "scope_id must be a raw id with no resource prefix."
  }
}

variable "project_prefix" {
  type        = string
  description = "Lowercase prefix for generated project ids. Placeholder: PROJECT_PREFIX."

  validation {
    condition     = can(regex("^[a-z][a-z0-9]{0,9}$", var.project_prefix))
    error_message = "project_prefix must be 1-10 characters, start with a letter, and use only lowercase letters and digits."
  }
}

variable "billing_account_id" {
  type        = string
  description = "Billing account to attach to new projects. Required unless scope_type is project."
  default     = null
}

variable "owner" {
  type        = string
  description = "Label value for owner. Lowercase, for example platform or security."
  default     = "platform"
}

variable "cost_center" {
  type        = string
  description = "Label value for cost-center."
  default     = "security"
}
