variable "network_project_id" {
  type        = string
  description = "Shared VPC host project, usually network-hub."
}

variable "region" {
  type        = string
  description = "Region for subnets, Cloud Router, and Cloud NAT."
  default     = "europe-west1"
}

variable "flow_log_sampling" {
  type        = number
  description = "VPC Flow Log sampling rate from 0 to 1. Lower is cheaper and less complete."
  default     = 0.5

  validation {
    condition     = var.flow_log_sampling > 0 && var.flow_log_sampling <= 1
    error_message = "flow_log_sampling must be in the range (0, 1]."
  }
}

variable "service_project_ids" {
  type        = list(string)
  description = "Projects attached to the Shared VPC host."
  default     = []
}

variable "enable_private_dns" {
  type        = bool
  description = "Create a private DNS zone that sends googleapis.com to the private.googleapis.com VIP."
  default     = true
}

variable "restrict_egress" {
  type        = bool
  description = "Deny egress to the internet except RFC1918 and the Private Google Access VIP. See the README for the package-update tradeoff."
  default     = true
}
