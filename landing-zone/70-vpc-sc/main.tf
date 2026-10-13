resource "terraform_data" "required_inputs" {
  count = var.enable_vpc_sc ? 1 : 0

  lifecycle {
    precondition {
      condition     = var.org_id != null && var.data_project_number != null && var.billing_project != null
      error_message = "enable_vpc_sc requires org_id, data_project_number, and billing_project."
    }
  }
}

resource "google_access_context_manager_access_policy" "this" {
  count  = var.enable_vpc_sc ? 1 : 0
  parent = "organizations/${var.org_id}"
  title  = "guardrails"

  depends_on = [terraform_data.required_inputs]
}

resource "google_access_context_manager_access_level" "corp" {
  count  = var.enable_vpc_sc ? 1 : 0
  parent = "accessPolicies/${google_access_context_manager_access_policy.this[0].name}"
  name   = "accessPolicies/${google_access_context_manager_access_policy.this[0].name}/accessLevels/corp_ip"
  title  = "corp_ip"

  basic {
    conditions {
      ip_subnetworks = var.allowed_ingress_cidrs
    }
  }
}

resource "google_access_context_manager_service_perimeter" "data" {
  count  = var.enable_vpc_sc ? 1 : 0
  parent = "accessPolicies/${google_access_context_manager_access_policy.this[0].name}"
  name   = "accessPolicies/${google_access_context_manager_access_policy.this[0].name}/servicePerimeters/data_sample"
  title  = "data_sample"
  # spec is the dry-run configuration. status is intentionally omitted so nothing is enforced.
  use_explicit_dry_run_spec = true

  spec {
    restricted_services = ["storage.googleapis.com", "bigquery.googleapis.com"]
    resources           = ["projects/${var.data_project_number}"]
    access_levels       = [google_access_context_manager_access_level.corp[0].name]

    ingress_policies {
      ingress_from {
        sources {
          access_level = google_access_context_manager_access_level.corp[0].name
        }
        identity_type = "ANY_IDENTITY"
      }
      ingress_to {
        resources = ["*"]
        operations {
          service_name = "storage.googleapis.com"
          method_selectors {
            method = "*"
          }
        }
      }
    }

    egress_policies {
      egress_from {
        identities = [var.egress_identity]
      }
      egress_to {
        resources = ["*"]
        operations {
          service_name = "bigquery.googleapis.com"
          method_selectors {
            method = "*"
          }
        }
      }
    }
  }
}
