locals {
  ci_member = "serviceAccount:${google_service_account.ci.email}"
}

# Access logs for the state bucket. This bucket is not itself logged; a second
# hop would recurse. State objects are still versioned and private.
resource "google_storage_bucket" "state_logs" {
  #checkov:skip=CKV_GCP_62:Access-log bucket. Logging it to another bucket only moves the problem and adds cost.
  name                        = "${var.state_bucket_name}-logs"
  location                    = var.location
  project                     = var.project_id
  force_destroy               = false
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type = "Delete"
    }
  }
}

resource "google_storage_bucket" "state" {
  name                        = var.state_bucket_name
  location                    = var.location
  project                     = var.project_id
  force_destroy               = false
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  logging {
    log_bucket        = google_storage_bucket.state_logs.name
    log_object_prefix = "state-access"
  }

  lifecycle_rule {
    condition {
      num_newer_versions = var.state_version_retention
      with_state         = "ARCHIVED"
    }
    action {
      type = "Delete"
    }
  }

  dynamic "encryption" {
    for_each = var.kms_key_name == null ? [] : [var.kms_key_name]
    content {
      default_kms_key_name = encryption.value
    }
  }
}

resource "google_kms_crypto_key_iam_member" "gcs_agent" {
  count         = var.kms_key_name == null || var.gcs_service_agent == null ? 0 : 1
  crypto_key_id = var.kms_key_name
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${var.gcs_service_agent}"
}

resource "google_service_account" "ci" {
  project      = var.project_id
  account_id   = "sa-terraform-ci"
  display_name = "Terraform CI"
  description  = "GitHub Actions apply identity. No JSON keys; Workload Identity Federation only."
}

resource "google_storage_bucket_iam_member" "ci_state" {
  bucket = google_storage_bucket.state.name
  role   = "roles/storage.objectAdmin"
  member = local.ci_member
}

resource "google_organization_iam_member" "ci" {
  for_each = var.org_id == null ? toset([]) : toset(var.ci_organization_roles)
  org_id   = var.org_id
  role     = each.value
  member   = local.ci_member
}

resource "google_billing_account_iam_member" "ci" {
  count              = var.billing_account_id == null ? 0 : 1
  billing_account_id = var.billing_account_id
  role               = "roles/billing.user"
  member             = local.ci_member
}

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = "github-pool"
  display_name              = "GitHub Actions"
  description               = "OIDC pool for this repository's GitHub Actions workflows."
}

resource "google_iam_workload_identity_pool_provider" "github" {
  #checkov:skip=CKV_GCP_125:The condition pins assertion.repository to one repository so pull-request plans from any ref in that repo succeed. assertion.sub also contains the ref, so an equality check on sub would reject every real GitHub token. Apply stays gated by the production environment.
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-provider"
  display_name                       = "GitHub OIDC"
  description                        = "Trusts token.actions.githubusercontent.com only for var.github_repository."

  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.ref"        = "assertion.ref"
    "attribute.actor"      = "assertion.actor"
  }

  # Forks fail this condition because assertion.repository is the fork, not the upstream.
  attribute_condition = "assertion.repository == \"${var.github_repository}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account_iam_member" "wif" {
  service_account_id = google_service_account.ci.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repository}"
}
