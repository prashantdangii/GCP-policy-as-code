module "iap" {
  source      = "../.."
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
