# Expected policies: VM-001 and VM-002 (no-external-ip-no-default-sa).
# Public IP plus the default Compute Engine service account.

resource "google_compute_instance" "exposed" {
  name         = "exposed"
  project      = "PROJECT_PREFIX-app-prod-sample"
  zone         = "europe-west1-b"
  machine_type = "e2-medium"
  labels = {
    owner         = "platform"
    env           = "nonprod"
    "cost-center" = "security"
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  service_account {
    email  = "123456789012-compute@developer.gserviceaccount.com"
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}
