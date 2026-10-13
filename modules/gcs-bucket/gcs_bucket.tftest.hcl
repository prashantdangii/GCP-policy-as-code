mock_provider "google" {}

variables {
  name       = "project-prefix-app-data"
  project_id = "PROJECT_ID"
  location   = "eu"
  labels = {
    owner         = "platform"
    env           = "nonprod"
    "cost-center" = "security"
  }
}

run "secure_defaults" {
  command = plan

  assert {
    condition     = google_storage_bucket.this.public_access_prevention == "enforced"
    error_message = "Public access prevention must default to enforced."
  }

  assert {
    condition     = google_storage_bucket.this.uniform_bucket_level_access == true
    error_message = "Uniform bucket-level access must stay on."
  }
}

run "rejects_public_without_justification" {
  command = plan

  variables {
    allow_public_access = true
    justification       = ""
  }

  expect_failures = [var.justification]
}

run "rejects_bad_env" {
  command = plan

  variables {
    labels = {
      owner         = "platform"
      env           = "staging"
      "cost-center" = "security"
    }
  }

  expect_failures = [var.labels]
}

run "rejects_location" {
  command = plan

  variables {
    location = "asia-east1"
  }

  expect_failures = [var.location]
}
