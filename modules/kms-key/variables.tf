variable "project_id" {
  type        = string
  description = "Project that owns the key ring."
}

variable "location" {
  type        = string
  description = "KMS location, for example europe-west1 or eu."
  default     = "europe-west1"
}

variable "key_ring_name" {
  type        = string
  description = "Key ring name."
}

variable "key_name" {
  type        = string
  description = "Crypto key name."
}

variable "rotation_period" {
  type        = string
  description = "Rotation period, at most 90 days. Default 7776000s."
  default     = "7776000s"

  validation {
    condition = (
      can(regex("^[0-9]+s$", var.rotation_period)) &&
      tonumber(trimsuffix(var.rotation_period, "s")) <= 7776000 &&
      tonumber(trimsuffix(var.rotation_period, "s")) >= 86400
    )
    error_message = "rotation_period must be between 1 day and 90 days, expressed in seconds (for example 7776000s)."
  }
}

variable "admin_member" {
  type        = string
  description = "Principal granted roles/cloudkms.admin. Must differ from user_member."
}

variable "user_member" {
  type        = string
  description = "Principal granted Encrypter/Decrypter. Must differ from admin_member."

  validation {
    condition     = var.user_member != var.admin_member
    error_message = "Key admin and key user must be different principals."
  }
}
