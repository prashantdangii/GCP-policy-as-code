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

resource "google_compute_instance" "this" {
  name         = var.name
  project      = var.project_id
  zone         = var.zone
  machine_type = var.machine_type
  tags         = var.tags
  labels       = local.labels

  boot_disk {
    initialize_params {
      image = var.boot_image
    }
    kms_key_self_link = var.disk_kms_key
  }

  network_interface {
    subnetwork = var.subnetwork

    dynamic "access_config" {
      for_each = var.allow_external_ip ? [1] : []
      content {}
    }
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  metadata = {
    enable-oslogin         = "TRUE"
    block-project-ssh-keys = "TRUE"
    serial-port-enable     = "FALSE"
  }

  service_account {
    email  = var.service_account_email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  #checkov:skip=CKV_GCP_32:Boot-disk CMEK is optional and covered by the advisory cmek-required policy.
  #checkov:skip=CKV_GCP_40:Public IP is blocked unless allow_external_ip and a justification are both set.
}
