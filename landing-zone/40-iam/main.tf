locals {
  parent = (
    var.scope_type == "organization" ? "organizations/${var.scope_id}" :
    var.scope_type == "folder" ? "folders/${var.scope_id}" :
    "projects/${var.scope_id}"
  )
  deny_parent = urlencode("cloudresourcemanager.googleapis.com/${local.parent}")

  # Read security posture. No mutate, no setIamPolicy, no key creation.
  viewer_permissions = [
    "cloudasset.assets.searchAllResources",
    "cloudasset.assets.searchAllIamPolicies",
    "resourcemanager.projects.get",
    "logging.logEntries.list",
    "logging.logs.list",
    "logging.sinks.get",
    "logging.sinks.list",
    "monitoring.alertPolicies.get",
    "monitoring.alertPolicies.list",
    "monitoring.timeSeries.list",
    "iam.roles.get",
    "iam.roles.list",
    "iam.serviceAccounts.get",
    "iam.serviceAccounts.list",
  ]

  # Deploy workloads. Cannot grant IAM and cannot create service-account keys.
  deployer_permissions = [
    "compute.instances.create",
    "compute.instances.delete",
    "compute.instances.get",
    "compute.instances.list",
    "compute.networks.get",
    "compute.subnetworks.use",
    "compute.disks.create",
    "storage.buckets.get",
    "storage.objects.create",
    "storage.objects.get",
    "storage.objects.list",
    "iam.serviceAccounts.actAs",
    "iam.serviceAccounts.get",
  ]
}

resource "google_organization_iam_custom_role" "security_viewer" {
  count       = var.scope_type == "organization" ? 1 : 0
  org_id      = var.scope_id
  role_id     = "customSecurityViewer"
  title       = "Custom Security Viewer"
  description = "Read assets, logs, and IAM configuration. No mutate permissions."
  permissions = local.viewer_permissions
}

resource "google_organization_iam_custom_role" "deployer" {
  count       = var.scope_type == "organization" ? 1 : 0
  org_id      = var.scope_id
  role_id     = "customDeployer"
  title       = "Custom Deployer"
  description = "Create and delete workload resources. No IAM admin and no service-account keys."
  permissions = local.deployer_permissions
}

resource "google_project_iam_custom_role" "security_viewer" {
  count       = var.scope_type == "project" ? 1 : 0
  project     = var.scope_id
  role_id     = "customSecurityViewer"
  title       = "Custom Security Viewer"
  description = "Read assets, logs, and IAM configuration. No mutate permissions."
  permissions = local.viewer_permissions
}

resource "google_project_iam_custom_role" "deployer" {
  count       = var.scope_type == "project" ? 1 : 0
  project     = var.scope_id
  role_id     = "customDeployer"
  title       = "Custom Deployer"
  description = "Create and delete workload resources. No IAM admin and no service-account keys."
  permissions = local.deployer_permissions
}

locals {
  viewer_role = one(concat(
    google_organization_iam_custom_role.security_viewer[*].name,
    google_project_iam_custom_role.security_viewer[*].name,
  ))
  deployer_role = one(concat(
    google_organization_iam_custom_role.deployer[*].name,
    google_project_iam_custom_role.deployer[*].name,
  ))
}

resource "google_organization_iam_member" "security_viewers" {
  count  = var.scope_type == "organization" ? 1 : 0
  org_id = var.scope_id
  role   = local.viewer_role
  member = "group:${var.security_group}"
}

resource "google_project_iam_member" "security_viewers" {
  count   = var.scope_type == "project" ? 1 : 0
  project = var.scope_id
  role    = local.viewer_role
  member  = "group:${var.security_group}"
}

resource "google_project_iam_member" "deployers" {
  project = var.security_project_id
  role    = local.deployer_role
  member  = "group:${var.deployer_group}"

  condition {
    title       = "expires-on-review-date"
    description = "Time-bound deployer access. Extend deployer_access_until after review."
    expression  = "request.time < timestamp(\"${var.deployer_access_until}\")"
  }
}

resource "google_iam_deny_policy" "sensitive" {
  parent       = local.deny_parent
  name         = "deny-sensitive-iam"
  display_name = "Deny service-account key creation"

  rules {
    description = "Nobody may create service-account keys except the break-glass group."
    deny_rule {
      denied_principals    = ["principalSet://goog/public:all"]
      exception_principals = [var.break_glass_principal]
      denied_permissions = [
        "iam.googleapis.com/serviceAccountKeys.create",
        "iam.googleapis.com/serviceAccounts.setIamPolicy",
      ]
    }
  }
}
