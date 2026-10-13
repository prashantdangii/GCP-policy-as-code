resource "google_compute_network_firewall_policy" "baseline" {
  name        = "baseline"
  project     = var.network_project_id
  description = "Shared VPC baseline. Deny by default, then explicit allows."
}

resource "google_compute_network_firewall_policy_association" "shared" {
  name              = "shared-vpc"
  project           = var.network_project_id
  attachment_target = google_compute_network.shared.id
  firewall_policy   = google_compute_network_firewall_policy.baseline.id
}

resource "google_compute_network_firewall_policy_rule" "deny_all_ingress" {
  project         = var.network_project_id
  firewall_policy = google_compute_network_firewall_policy.baseline.name
  action          = "deny"
  direction       = "INGRESS"
  priority        = 65534
  rule_name       = "deny-all-ingress"
  description     = "Default deny all ingress. Admin access is IAP-only at a higher priority."
  enable_logging  = true

  match {
    src_ip_ranges = ["0.0.0.0/0"]
    layer4_configs {
      ip_protocol = "all"
    }
  }
}

resource "google_compute_network_firewall_policy_rule" "allow_rfc1918_egress" {
  count           = var.restrict_egress ? 1 : 0
  project         = var.network_project_id
  firewall_policy = google_compute_network_firewall_policy.baseline.name
  action          = "allow"
  direction       = "EGRESS"
  priority        = 1000
  rule_name       = "allow-rfc1918-egress"
  description     = "East-west traffic inside RFC1918."
  enable_logging  = true

  match {
    dest_ip_ranges = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
    layer4_configs {
      ip_protocol = "all"
    }
  }
}

resource "google_compute_network_firewall_policy_rule" "allow_private_google_egress" {
  count           = var.restrict_egress ? 1 : 0
  project         = var.network_project_id
  firewall_policy = google_compute_network_firewall_policy.baseline.name
  action          = "allow"
  direction       = "EGRESS"
  priority        = 1100
  rule_name       = "allow-private-google-egress"
  description     = "HTTPS to the Private Google Access VIP (199.36.153.8/30)."
  enable_logging  = true

  match {
    dest_ip_ranges = ["199.36.153.8/30"]
    layer4_configs {
      ip_protocol = "tcp"
      ports       = ["443"]
    }
  }
}

resource "google_compute_network_firewall_policy_rule" "deny_internet_egress" {
  count           = var.restrict_egress ? 1 : 0
  project         = var.network_project_id
  firewall_policy = google_compute_network_firewall_policy.baseline.name
  action          = "deny"
  direction       = "EGRESS"
  priority        = 65534
  rule_name       = "deny-internet-egress"
  description     = "Block direct internet egress. OS packages need an explicit allow or restrict_egress = false."
  enable_logging  = true

  match {
    dest_ip_ranges = ["0.0.0.0/0"]
    layer4_configs {
      ip_protocol = "all"
    }
  }
}

module "allow_iap" {
  source      = "../../modules/firewall-rule"
  name        = "allow-iap-admin"
  project_id  = var.network_project_id
  network     = google_compute_network.shared.name
  direction   = "INGRESS"
  action      = "allow"
  protocol    = "tcp"
  ports       = ["22", "3389"]
  ranges      = ["35.235.240.0/20"]
  priority    = 1000
  description = "SSH and RDP only from Identity-Aware Proxy"
  target_tags = ["iap-ssh"]
}

module "allow_health_checks" {
  source      = "../../modules/firewall-rule"
  name        = "allow-health-checks"
  project_id  = var.network_project_id
  network     = google_compute_network.shared.name
  direction   = "INGRESS"
  action      = "allow"
  protocol    = "tcp"
  ports       = ["80", "443"]
  ranges      = ["35.191.0.0/16", "130.211.0.0/22", "209.85.152.0/22", "209.85.204.0/22"]
  priority    = 1100
  description = "Google Cloud load-balancer health checks"
  target_tags = ["lb-backend"]
}
