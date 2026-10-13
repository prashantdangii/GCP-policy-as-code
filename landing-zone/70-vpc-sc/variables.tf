variable "enable_vpc_sc" {
  type        = bool
  description = "Create the Access Context Manager policy and a dry-run perimeter. Default false."
  default     = false
}

variable "region" {
  type        = string
  description = "Provider region."
  default     = "europe-west1"
}

variable "org_id" {
  type        = string
  description = "Organization id. Required when enable_vpc_sc is true. Access policies are org-scoped."
  default     = null
}

variable "billing_project" {
  type        = string
  description = "Project used as the billing/quota project for Access Context Manager API calls."
  default     = null
}

variable "data_project_number" {
  type        = string
  description = "Numeric project number for data-sample. Perimeter resources use numbers, not project ids."
  default     = null
}

variable "egress_identity" {
  type        = string
  description = "Service account allowed to call BigQuery from inside the dry-run perimeter."
  default     = "serviceAccount:app-runtime@example.com"
}

variable "allowed_ingress_cidrs" {
  type        = list(string)
  description = "Corporate CIDRs for the dry-run access level. 203.0.113.0/24 is TEST-NET-3, a documentation range."
  default     = ["203.0.113.0/24"]
}
