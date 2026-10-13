# Expected policy: CMEK-001 (cmek-required, advisory).
# Uniform access and labels are correct. Only the KMS key is missing.

resource "google_storage_bucket" "no_cmek" {
  name                        = "project-prefix-no-cmek"
  project                     = "PROJECT_PREFIX-app-prod-sample"
  location                    = "europe-west1"
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  labels = {
    owner         = "platform"
    env           = "prod"
    "cost-center" = "security"
  }
}
