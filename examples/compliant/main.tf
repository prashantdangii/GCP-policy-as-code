locals {
  labels = {
    owner         = "platform"
    env           = "prod"
    "cost-center" = "security"
  }
  project_id = "PROJECT_PREFIX-app-prod-sample"
}

module "runtime" {
  source = "../../modules/service-account"

  project_id   = local.project_id
  account_id   = "app-runtime"
  display_name = "App runtime"
  description  = "Least-privilege runtime identity for the sample app. No JSON keys."
}

module "key" {
  source = "../../modules/kms-key"

  project_id    = local.project_id
  location      = "europe-west1"
  key_ring_name = "app"
  key_name      = "data"
  admin_member  = "group:kms-admins@example.com"
  user_member   = "serviceAccount:${module.runtime.email}"
}

module "bucket" {
  source = "../../modules/gcs-bucket"

  name         = "project-prefix-app-data"
  project_id   = local.project_id
  location     = "europe-west1"
  labels       = local.labels
  kms_key_name = module.key.key_id
}

module "dataset" {
  source = "../../modules/bigquery-dataset"

  dataset_id   = "app_analytics"
  project_id   = local.project_id
  location     = "EU"
  labels       = local.labels
  kms_key_name = module.key.key_id
  authorized_groups = {
    "analysts@example.com" = "roles/bigquery.dataViewer"
  }
}

module "iap_ssh" {
  source = "../../modules/firewall-rule"

  name        = "allow-iap-ssh"
  project_id  = local.project_id
  network     = "shared-vpc"
  direction   = "INGRESS"
  action      = "allow"
  protocol    = "tcp"
  ports       = ["22"]
  ranges      = ["35.235.240.0/20"]
  priority    = 1000
  description = "SSH only from Identity-Aware Proxy."
  target_tags = ["iap-ssh"]
}

module "instance" {
  source = "../../modules/compute-instance"

  name                  = "app"
  project_id            = local.project_id
  zone                  = "europe-west1-b"
  subnetwork            = "prod"
  service_account_email = module.runtime.email
  labels                = local.labels
  disk_kms_key          = module.key.key_id
}
