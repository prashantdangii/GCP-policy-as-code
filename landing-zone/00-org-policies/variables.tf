variable "region" {
  type        = string
  description = "Provider region. Org policies themselves are not regional."
  default     = "europe-west1"
}

variable "scope_type" {
  type        = string
  description = "Where policies attach. organization, folder, or project. Use project when you have no Cloud Identity org."

  validation {
    condition     = contains(["organization", "folder", "project"], var.scope_type)
    error_message = "scope_type must be organization, folder, or project."
  }
}

variable "scope_id" {
  type        = string
  description = "Organization id, folder id, or project id. No resource prefix."

  validation {
    condition     = length(trimspace(var.scope_id)) > 0 && !strcontains(var.scope_id, "/")
    error_message = "scope_id is the raw id, for example ORG_ID or a project id, with no organizations/ prefix."
  }
}

variable "allowed_locations" {
  type        = list(string)
  description = "Value group or locations allowed by gcp.resourceLocations."
  default     = ["in:eu-locations", "in:us-locations"]
}

variable "exceptions" {
  type = map(list(object({
    parent         = string
    reason         = string
    expires        = string
    kind           = string
    allowed_values = optional(list(string), [])
  })))
  description = "Constraint name to child-scope exceptions. reason and expires (YYYY-MM-DD) are mandatory. kind is boolean or list."
  default     = {}

  validation {
    condition = alltrue(flatten([
      for _, items in var.exceptions : [
        for item in items : (
          length(trimspace(item.reason)) > 0 &&
          can(regex("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", item.expires)) &&
          contains(["boolean", "list"], item.kind) &&
          (startswith(item.parent, "folders/") || startswith(item.parent, "projects/"))
        )
      ]
    ]))
    error_message = "Each exception needs a non-empty reason, expires as YYYY-MM-DD, kind boolean or list, and a parent of folders/ID or projects/ID."
  }
}
