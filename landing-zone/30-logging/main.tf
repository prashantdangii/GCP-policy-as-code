locals {
  parent = (
    var.scope_type == "organization" ? "organizations/${var.scope_id}" :
    var.scope_type == "folder" ? "folders/${var.scope_id}" :
    "projects/${var.scope_id}"
  )
  bq_destination  = "bigquery.googleapis.com/projects/${var.logging_project_id}/datasets/${google_bigquery_dataset.audit.dataset_id}"
  gcs_destination = "storage.googleapis.com/${google_storage_bucket.archive.name}"
}

resource "google_bigquery_dataset" "audit" {
  dataset_id                  = var.audit_dataset_id
  project                     = var.logging_project_id
  location                    = var.dataset_location
  default_table_expiration_ms = var.default_table_expiration_ms
  delete_contents_on_destroy  = false
  description                 = "Aggregated audit logs. Partitioning is applied by the Logging sink on the date-sharded or partitioned destination tables."

  labels = {
    owner         = "platform"
    env           = "shared"
    "cost-center" = "security"
  }

  dynamic "default_encryption_configuration" {
    for_each = var.kms_key_name == null ? [] : [var.kms_key_name]
    content {
      kms_key_name = default_encryption_configuration.value
    }
  }
}

resource "google_storage_bucket" "archive" {
  #checkov:skip=CKV_GCP_62:This bucket is the archive destination. Access logs would recurse into the same sink.
  name                        = var.archive_bucket_name
  project                     = var.logging_project_id
  location                    = var.bucket_location
  force_destroy               = false
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  retention_policy {
    retention_period = var.retention_period_seconds
    is_locked        = var.lock_retention
  }

  dynamic "encryption" {
    for_each = var.kms_key_name == null ? [] : [var.kms_key_name]
    content {
      default_kms_key_name = encryption.value
    }
  }
}

resource "google_logging_project_bucket_config" "default_bucket" {
  project        = var.logging_project_id
  location       = "global"
  bucket_id      = "_Default"
  retention_days = var.log_bucket_retention_days
}

resource "google_logging_organization_sink" "bigquery" {
  count            = var.scope_type == "organization" ? 1 : 0
  name             = "aggregated-audit-bq"
  org_id           = var.scope_id
  destination      = local.bq_destination
  include_children = true
  description      = "Org-level copy of audit logs into BigQuery."

  dynamic "exclusions" {
    for_each = var.exclusion_filters
    content {
      name        = exclusions.value.name
      filter      = exclusions.value.filter
      description = exclusions.value.description
    }
  }
}

resource "google_logging_organization_sink" "archive" {
  count            = var.scope_type == "organization" ? 1 : 0
  name             = "aggregated-audit-gcs"
  org_id           = var.scope_id
  destination      = local.gcs_destination
  include_children = true
  description      = "Org-level WORM-style archive of audit logs."

  dynamic "exclusions" {
    for_each = var.exclusion_filters
    content {
      name        = exclusions.value.name
      filter      = exclusions.value.filter
      description = exclusions.value.description
    }
  }
}

resource "google_logging_folder_sink" "bigquery" {
  count            = var.scope_type == "folder" ? 1 : 0
  name             = "aggregated-audit-bq"
  folder           = local.parent
  destination      = local.bq_destination
  include_children = true
  description      = "Folder-level copy of audit logs into BigQuery."

  dynamic "exclusions" {
    for_each = var.exclusion_filters
    content {
      name        = exclusions.value.name
      filter      = exclusions.value.filter
      description = exclusions.value.description
    }
  }
}

resource "google_logging_folder_sink" "archive" {
  count            = var.scope_type == "folder" ? 1 : 0
  name             = "aggregated-audit-gcs"
  folder           = local.parent
  destination      = local.gcs_destination
  include_children = true
  description      = "Folder-level archive of audit logs."

  dynamic "exclusions" {
    for_each = var.exclusion_filters
    content {
      name        = exclusions.value.name
      filter      = exclusions.value.filter
      description = exclusions.value.description
    }
  }
}

resource "google_logging_project_sink" "bigquery" {
  count       = var.scope_type == "project" ? 1 : 0
  name        = "aggregated-audit-bq"
  project     = var.scope_id
  destination = local.bq_destination
  description = "Project-level copy of audit logs. include_children does not exist on project sinks."

  dynamic "exclusions" {
    for_each = var.exclusion_filters
    content {
      name        = exclusions.value.name
      filter      = exclusions.value.filter
      description = exclusions.value.description
    }
  }
}

resource "google_logging_project_sink" "archive" {
  count       = var.scope_type == "project" ? 1 : 0
  name        = "aggregated-audit-gcs"
  project     = var.scope_id
  destination = local.gcs_destination
  description = "Project-level archive of audit logs."

  dynamic "exclusions" {
    for_each = var.exclusion_filters
    content {
      name        = exclusions.value.name
      filter      = exclusions.value.filter
      description = exclusions.value.description
    }
  }
}

locals {
  writer_identity = one(concat(
    google_logging_organization_sink.bigquery[*].writer_identity,
    google_logging_folder_sink.bigquery[*].writer_identity,
    google_logging_project_sink.bigquery[*].writer_identity,
  ))
  archive_writer = one(concat(
    google_logging_organization_sink.archive[*].writer_identity,
    google_logging_folder_sink.archive[*].writer_identity,
    google_logging_project_sink.archive[*].writer_identity,
  ))
}

resource "google_bigquery_dataset_iam_member" "writer" {
  dataset_id = google_bigquery_dataset.audit.dataset_id
  project    = var.logging_project_id
  role       = "roles/bigquery.dataEditor"
  member     = local.writer_identity
}

resource "google_storage_bucket_iam_member" "writer" {
  bucket = google_storage_bucket.archive.name
  role   = "roles/storage.objectCreator"
  member = local.archive_writer
}

resource "google_organization_iam_audit_config" "all_services" {
  count   = var.scope_type == "organization" ? 1 : 0
  org_id  = var.scope_id
  service = "allServices"

  audit_log_config {
    log_type = "ADMIN_READ"
  }
  audit_log_config {
    log_type         = "DATA_READ"
    exempted_members = var.audit_exempted_members
  }
  audit_log_config {
    log_type         = "DATA_WRITE"
    exempted_members = var.audit_exempted_members
  }
}

resource "google_folder_iam_audit_config" "all_services" {
  count   = var.scope_type == "folder" ? 1 : 0
  folder  = local.parent
  service = "allServices"

  audit_log_config {
    log_type = "ADMIN_READ"
  }
  audit_log_config {
    log_type         = "DATA_READ"
    exempted_members = var.audit_exempted_members
  }
  audit_log_config {
    log_type         = "DATA_WRITE"
    exempted_members = var.audit_exempted_members
  }
}

resource "google_project_iam_audit_config" "all_services" {
  count   = var.scope_type == "project" ? 1 : 0
  project = var.scope_id
  service = "allServices"

  audit_log_config {
    log_type = "ADMIN_READ"
  }
  audit_log_config {
    log_type         = "DATA_READ"
    exempted_members = var.audit_exempted_members
  }
  audit_log_config {
    log_type         = "DATA_WRITE"
    exempted_members = var.audit_exempted_members
  }
}
