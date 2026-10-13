resource "google_compute_firewall" "this" {
  name        = var.name
  project     = var.project_id
  network     = var.network
  direction   = upper(var.direction)
  priority    = var.priority
  description = var.description

  source_ranges           = upper(var.direction) == "INGRESS" ? var.ranges : null
  destination_ranges      = upper(var.direction) == "EGRESS" ? var.ranges : null
  target_tags             = length(var.target_tags) == 0 ? null : var.target_tags
  target_service_accounts = length(var.target_service_accounts) == 0 ? null : var.target_service_accounts

  dynamic "allow" {
    for_each = var.action == "allow" ? [1] : []
    content {
      protocol = var.protocol
      ports    = length(var.ports) == 0 ? null : var.ports
    }
  }

  dynamic "deny" {
    for_each = var.action == "deny" ? [1] : []
    content {
      protocol = var.protocol
      ports    = length(var.ports) == 0 ? null : var.ports
    }
  }

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}
