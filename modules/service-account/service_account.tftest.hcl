mock_provider "google" {}

variables {
  project_id   = "PROJECT_ID"
  account_id   = "app-runtime"
  display_name = "App runtime"
  description  = "Runtime identity for the sample app. No JSON keys."
}

run "creates_account_without_a_key" {
  command = plan

  assert {
    condition     = google_service_account.this.account_id == "app-runtime"
    error_message = "Service account id was not applied."
  }
}

run "rejects_empty_description" {
  command = plan

  variables {
    description = "  "
  }

  expect_failures = [var.description]
}
