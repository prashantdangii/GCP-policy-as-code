mock_provider "google" {}

variables {
  name        = "allow-iap-ssh"
  project_id  = "PROJECT_ID"
  network     = "shared-vpc"
  direction   = "INGRESS"
  action      = "allow"
  protocol    = "tcp"
  ports       = ["22", "3389"]
  ranges      = ["35.235.240.0/20"]
  priority    = 1000
  description = "SSH and RDP from Identity-Aware Proxy only"
  target_tags = ["iap-ssh"]
}

run "allows_iap_admin" {
  command = plan

  assert {
    condition     = google_compute_firewall.this.direction == "INGRESS"
    error_message = "IAP rule should be ingress."
  }
}

run "rejects_world_ssh" {
  command = plan

  variables {
    ranges                 = ["0.0.0.0/0"]
    allow_open_admin_ports = false
    justification          = ""
  }

  expect_failures = [var.justification]
}

run "rejects_override_without_justification" {
  command = plan

  variables {
    ranges                 = ["0.0.0.0/0"]
    allow_open_admin_ports = true
    justification          = "   "
  }

  expect_failures = [var.justification]
}

run "rejects_untargeted_rule" {
  command = plan

  variables {
    target_tags             = []
    target_service_accounts = []
  }

  expect_failures = [var.target_tags]
}
