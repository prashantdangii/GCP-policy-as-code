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

resource "google_bigquery_dataset" "this" {
  dataset_id                  = var.dataset_id
  project                     = var.project_id
  location                    = var.location
  labels                      = local.labels
  default_table_expiration_ms = var.default_table_expiration_ms
  delete_contents_on_destroy  = var.delete_contents_on_destroy

  dynamic "default_encryption_configuration" {
    for_each = var.kms_key_name == null ? [] : [var.kms_key_name]
    content {
      kms_key_name = default_encryption_configuration.value
    }
  }

  dynamic "access" {
    for_each = var.authorized_groups
    content {
      role           = access.value
      group_by_email = access.key
    }
  }
}
