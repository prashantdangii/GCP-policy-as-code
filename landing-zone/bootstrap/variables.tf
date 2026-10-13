variable "project_id" {
  type        = string
  description = "Bootstrap project that holds Terraform state and the CI service account. The human creates this project before the first apply."
}

variable "region" {
  type        = string
  description = "Default region for provider operations."
  default     = "europe-west1"
}

variable "state_bucket_name" {
  type        = string
  description = "Globally unique name for the Terraform state bucket. Example: PROJECT_PREFIX-tfstate."

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9._-]{1,61}[a-z0-9]$", var.state_bucket_name))
    error_message = "state_bucket_name must be a valid GCS bucket name."
  }
}

variable "location" {
  type        = string
  description = "Location for the state and access-log buckets. Use a multi-region or region allowed by the resource-location org policy."
  default     = "eu"
}

variable "github_repository" {
  type        = string
  description = "GitHub repository allowed to impersonate the CI service account, in ORG/REPO form."

  validation {
    condition     = can(regex("^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", var.github_repository))
    error_message = "github_repository must look like GITHUB_ORG/REPO."
  }
}

variable "kms_key_name" {
  type        = string
  description = "Optional CMEK for the state bucket. Null keeps Google-managed encryption."
  default     = null
}

variable "gcs_service_agent" {
  type        = string
  description = "Optional GCS service-agent email that needs Encrypter/Decrypter when kms_key_name is set."
  default     = null
}

variable "org_id" {
  type        = string
  description = "Optional organization id (numeric) used to grant the CI service account org-scoped roles. Leave null for a project-only lab."
  default     = null
}

variable "billing_account_id" {
  type        = string
  description = "Optional billing account id. When set, the CI service account receives roles/billing.user."
  default     = null
}

variable "ci_organization_roles" {
  type        = list(string)
  description = "Org-scoped roles for the CI service account. Primitive roles are intentionally absent."
  default = [
    "roles/resourcemanager.folderAdmin",
    "roles/resourcemanager.projectCreator",
    "roles/orgpolicy.policyAdmin",
    "roles/logging.configWriter",
    "roles/iam.organizationRoleAdmin",
    "roles/iam.denyAdmin",
    "roles/compute.xpnAdmin",
    "roles/accesscontextmanager.policyAdmin",
  ]
}

variable "state_version_retention" {
  type        = number
  description = "Number of newer object versions to keep on the state bucket before lifecycle deletion."
  default     = 10
}
