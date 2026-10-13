mock_provider "google" {}

variables {
  dataset_id = "app_analytics"
  project_id = "PROJECT_ID"
  location   = "EU"
  labels = {
    owner         = "platform"
    env           = "prod"
    "cost-center" = "security"
  }
}

run "secure_defaults" {
  command = plan

  assert {
    condition     = google_bigquery_dataset.this.dataset_id == "app_analytics"
    error_message = "Dataset id was not applied."
  }
}

run "rejects_all_users" {
  command = plan

  variables {
    authorized_groups = {
      "allUsers" = "roles/bigquery.dataViewer"
    }
  }

  expect_failures = [var.authorized_groups]
}
