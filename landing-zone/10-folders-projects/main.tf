locals {
  create_hierarchy = var.scope_type != "project"
  parent = (
    var.scope_type == "organization" ? "organizations/${var.scope_id}" :
    var.scope_type == "folder" ? "folders/${var.scope_id}" :
    null
  )

  folders = {
    prod    = "prod"
    nonprod = "nonprod"
    shared  = "shared-services"
  }

  projects = {
    logging-hub = {
      folder         = "shared"
      env            = "shared"
      classification = "restricted"
      apis = [
        "logging.googleapis.com",
        "bigquery.googleapis.com",
        "storage.googleapis.com",
        "iam.googleapis.com",
        "monitoring.googleapis.com",
      ]
    }
    network-hub = {
      folder         = "shared"
      env            = "shared"
      classification = "internal"
      apis = [
        "compute.googleapis.com",
        "dns.googleapis.com",
        "servicenetworking.googleapis.com",
        "iam.googleapis.com",
      ]
    }
    sec-tooling = {
      folder         = "shared"
      env            = "shared"
      classification = "restricted"
      apis = [
        "cloudasset.googleapis.com",
        "iam.googleapis.com",
        "logging.googleapis.com",
        "cloudkms.googleapis.com",
        "serviceusage.googleapis.com",
        "accesscontextmanager.googleapis.com",
      ]
    }
    app-prod-sample = {
      folder         = "prod"
      env            = "prod"
      classification = "confidential"
      apis = [
        "compute.googleapis.com",
        "iam.googleapis.com",
        "oslogin.googleapis.com",
      ]
    }
    app-nonprod-sample = {
      folder         = "nonprod"
      env            = "nonprod"
      classification = "internal"
      apis = [
        "compute.googleapis.com",
        "iam.googleapis.com",
        "oslogin.googleapis.com",
      ]
    }
    data-sample = {
      folder         = "prod"
      env            = "prod"
      classification = "restricted"
      apis = [
        "bigquery.googleapis.com",
        "storage.googleapis.com",
        "iam.googleapis.com",
      ]
    }
  }

  services = flatten([
    for name, cfg in local.projects : [
      for api in cfg.apis : {
        key     = "${name}/${api}"
        project = name
        api     = api
      }
    ]
  ])
}

resource "terraform_data" "billing_required" {
  lifecycle {
    precondition {
      condition     = !local.create_hierarchy || (var.billing_account_id != null && length(var.billing_account_id) > 0)
      error_message = "billing_account_id is required when scope_type creates projects."
    }
  }
}

resource "google_folder" "env" {
  for_each            = local.create_hierarchy ? local.folders : {}
  display_name        = each.value
  parent              = local.parent
  deletion_protection = true
}

resource "google_project" "projects" {
  #checkov:skip=CKV2_GCP_5:Data Access audit config is applied once in landing-zone/30-logging at the organization, folder, or project scope.
  for_each            = local.create_hierarchy ? local.projects : {}
  name                = each.key
  project_id          = "${var.project_prefix}-${each.key}"
  folder_id           = google_folder.env[each.value.folder].name
  billing_account     = var.billing_account_id
  auto_create_network = false
  deletion_policy     = "PREVENT"
  labels = {
    owner               = var.owner
    env                 = each.value.env
    "cost-center"       = var.cost_center
    data-classification = each.value.classification
  }

  depends_on = [terraform_data.billing_required]
}

resource "google_project_service" "apis" {
  for_each           = local.create_hierarchy ? { for svc in local.services : svc.key => svc } : {}
  project            = google_project.projects[each.value.project].project_id
  service            = each.value.api
  disable_on_destroy = false
}
