# Expected policy: FW-001 (no-open-admin-ports / firewall.rego).
# Ingress SSH from the whole internet.

resource "google_compute_firewall" "ssh_world" {
  name          = "allow-ssh-world"
  project       = "PROJECT_PREFIX-app-prod-sample"
  network       = "shared-vpc"
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]
  description   = "Intentionally open SSH. This file must fail policy checks."
  priority      = 1000

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}
