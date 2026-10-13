locals {
  labels = merge(
    {
      owner         = var.labels["owner"]
      env           = var.labels["env"]
      "cost-center" = var.labels["cost-center"]
    },
    var.extra_labels,
  )
}

#checkov:skip=CKV_GCP_62:Access logging is optional. The landing-zone aggregated sink covers audit; set log_bucket to add access logs.
#checkov:skip=CKV_GCP_5:CMEK is optional and promoted by the advisory cmek-required policy. Google-managed encryption is the default.

resource "google_storage_bucket" "this" {
  name                        = var.name
  project                     = var.project_id
  location                    = var.location
  force_destroy               = var.force_destroy
  uniform_bucket_level_access = true
  public_access_prevention    = var.allow_public_access ? "inherited" : "enforced"
  labels                      = local.labels

  versioning {
    enabled = true
  }

  dynamic "logging" {
    for_each = var.log_bucket == null ? [] : [var.log_bucket]
    content {
      log_bucket        = logging.value
      log_object_prefix = var.name
    }
  }

  dynamic "encryption" {
    for_each = var.kms_key_name == null ? [] : [var.kms_key_name]
    content {
      default_kms_key_name = encryption.value
    }
  }

  dynamic "retention_policy" {
    for_each = var.retention_seconds == null ? [] : [var.retention_seconds]
    content {
      retention_period = retention_policy.value
      is_locked        = var.lock_retention
    }
  }
}
