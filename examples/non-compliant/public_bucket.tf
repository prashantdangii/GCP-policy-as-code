# Expected policy: GCS-001 (gcs-bucket-secure / gcs_bucket.rego).
# Uniform access is off and public access prevention is inherited.

resource "google_storage_bucket" "public" {
  name                        = "project-prefix-public"
  project                     = "PROJECT_PREFIX-app-prod-sample"
  location                    = "europe-west1"
  uniform_bucket_level_access = false
  public_access_prevention    = "inherited"
  labels = {
    owner         = "platform"
    env           = "nonprod"
    "cost-center" = "security"
  }

  encryption {
    default_kms_key_name = "projects/PROJECT_PREFIX-app-prod-sample/locations/europe-west1/keyRings/app/cryptoKeys/data"
  }
}
