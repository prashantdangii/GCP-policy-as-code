output "parent" {
  description = "Resource name the baseline policies are attached to."
  value       = local.parent
}

output "boolean_constraints" {
  description = "Boolean org-policy constraints enforced by this stack."
  value       = keys(local.boolean_constraints)
}

output "exceptions" {
  description = "Exception parents, reasons, and expiry dates. Review dates are not enforced by the Org Policy API."
  value = [
    for item in local.exception_items : {
      constraint = item.constraint
      parent     = item.parent
      reason     = item.reason
      expires    = item.expires
    }
  ]
}
