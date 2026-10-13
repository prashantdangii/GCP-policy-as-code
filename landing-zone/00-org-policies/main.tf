locals {
  parent = (
    var.scope_type == "organization" ? "organizations/${var.scope_id}" :
    var.scope_type == "folder" ? "folders/${var.scope_id}" :
    "projects/${var.scope_id}"
  )

  # Boolean constraints. enforce = TRUE turns the protective behavior on.
  boolean_constraints = {
    "iam.disableServiceAccountKeyCreation"            = "Block creation of long-lived service account keys."
    "iam.disableServiceAccountKeyUpload"              = "Block upload of externally generated service account keys."
    "iam.automaticIamGrantsForDefaultServiceAccounts" = "Stop default service accounts from receiving Editor."
    "compute.requireOsLogin"                          = "Require OS Login so SSH is IAM-based."
    "compute.skipDefaultNetworkCreation"              = "Do not create the permissive default VPC."
    "compute.disableSerialPortAccess"                 = "Disable serial-port access on Compute instances."
    "compute.requireShieldedVm"                       = "Require Shielded VM (secure boot, vTPM, integrity monitoring)."
    "storage.uniformBucketLevelAccess"                = "Force uniform bucket-level access and ignore object ACLs."
    "storage.publicAccessPrevention"                  = "Block public Cloud Storage buckets."
    "sql.restrictPublicIp"                            = "Refuse public IPv4 on Cloud SQL."
  }

  exception_items = flatten([
    for constraint, items in var.exceptions : [
      for item in items : {
        key            = "${constraint}|${item.parent}"
        constraint     = constraint
        parent         = item.parent
        reason         = item.reason
        expires        = item.expires
        kind           = item.kind
        allowed_values = item.allowed_values
      }
    ]
  ])
}

resource "google_org_policy_policy" "boolean" {
  for_each = local.boolean_constraints
  name     = "${local.parent}/policies/${each.key}"
  parent   = local.parent

  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

resource "google_org_policy_policy" "deny_external_ip" {
  name   = "${local.parent}/policies/compute.vmExternalIpAccess"
  parent = local.parent

  spec {
    rules {
      deny_all = "TRUE"
    }
  }
}

resource "google_org_policy_policy" "resource_locations" {
  name   = "${local.parent}/policies/gcp.resourceLocations"
  parent = local.parent

  spec {
    inherit_from_parent = false
    rules {
      values {
        allowed_values = var.allowed_locations
      }
    }
  }
}

# Child policies override the parent for that constraint. Terraform cannot
# expire them; docs/rollout-strategy.md owns the review of `expires`.
resource "google_org_policy_policy" "exception" {
  for_each = { for item in local.exception_items : item.key => item }
  name     = "${each.value.parent}/policies/${each.value.constraint}"
  parent   = each.value.parent

  spec {
    dynamic "rules" {
      for_each = each.value.kind == "boolean" ? [1] : []
      content {
        enforce = "FALSE"
      }
    }

    dynamic "rules" {
      for_each = each.value.kind == "list" && length(each.value.allowed_values) == 0 ? [1] : []
      content {
        allow_all = "TRUE"
      }
    }

    dynamic "rules" {
      for_each = each.value.kind == "list" && length(each.value.allowed_values) > 0 ? [1] : []
      content {
        values {
          allowed_values = each.value.allowed_values
        }
      }
    }
  }
}
