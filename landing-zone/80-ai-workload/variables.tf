variable "enable_ai_workload" {
  type        = bool
  description = "Create the Vertex sample identity and endpoint. Default false so a normal apply does not bill Vertex."
  default     = false
}

variable "project_id" {
  type        = string
  description = "Project for the sample, usually data-sample."
}

variable "region" {
  type        = string
  description = "Vertex location."
  default     = "europe-west1"
}

variable "network_name" {
  type        = string
  description = "Optional Shared VPC name. When set, an egress allow for the runtime service account is created."
  default     = null
}

variable "network_project_id" {
  type        = string
  description = "Project that owns network_name. Required when network_name is set."
  default     = null
}

variable "kms_key_name" {
  type        = string
  description = "Optional CMEK id recorded for the workload. Endpoint CMEK support varies by product; this output is the contract."
  default     = null
}
