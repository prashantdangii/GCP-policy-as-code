mock_provider "google" {}

variables {
  project_id    = "PROJECT_ID"
  location      = "europe-west1"
  key_ring_name = "data"
  key_name      = "app"
  admin_member  = "group:grp-key-admins@example.com"
  user_member   = "serviceAccount:app-runtime@PROJECT_ID.iam.gserviceaccount.com"
}

run "separates_admin_and_user" {
  command = plan

  assert {
    condition     = google_kms_crypto_key.this.rotation_period == "7776000s"
    error_message = "Rotation should default to 90 days."
  }
}

run "rejects_shared_principal" {
  command = plan

  variables {
    user_member = "group:grp-key-admins@example.com"
  }

  expect_failures = [var.user_member]
}

run "rejects_slow_rotation" {
  command = plan

  variables {
    rotation_period = "31536000s"
  }

  expect_failures = [var.rotation_period]
}
