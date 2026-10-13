# Expected policy: LBL-001 (required-labels / labels.rego).
# The disk is encrypted, so this file isolates the missing-label violation.

resource "google_compute_disk" "unlabeled" {
  name    = "unlabeled"
  project = "PROJECT_PREFIX-app-prod-sample"
  zone    = "europe-west1-b"
  size    = 10
  type    = "pd-balanced"

  disk_encryption_key {
    kms_key_self_link = "projects/PROJECT_PREFIX-app-prod-sample/locations/europe-west1/keyRings/app/cryptoKeys/data"
  }
}
