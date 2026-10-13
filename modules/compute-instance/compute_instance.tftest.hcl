mock_provider "google" {}

variables {
  name                  = "app-sample"
  project_id            = "PROJECT_ID"
  zone                  = "europe-west1-b"
  subnetwork            = "projects/PROJECT_ID/regions/europe-west1/subnetworks/prod"
  service_account_email = "app-runtime@PROJECT_ID.iam.gserviceaccount.com"
  labels = {
    owner         = "platform"
    env           = "prod"
    "cost-center" = "security"
  }
}

run "secure_defaults" {
  command = plan

  assert {
    condition     = length(google_compute_instance.this.network_interface[0].access_config) == 0
    error_message = "The instance must not have an access_config by default."
  }
}

run "rejects_default_service_account" {
  command = plan

  variables {
    service_account_email = "123456789-compute@developer.gserviceaccount.com"
  }

  expect_failures = [var.service_account_email]
}

run "rejects_external_ip_without_justification" {
  command = plan

  variables {
    allow_external_ip = true
    justification     = ""
  }

  expect_failures = [var.justification]
}
