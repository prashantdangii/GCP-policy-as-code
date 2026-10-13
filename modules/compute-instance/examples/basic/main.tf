module "vm" {
  source                = "../.."
  name                  = "app-sample"
  project_id            = "PROJECT_ID"
  zone                  = "europe-west1-b"
  subnetwork            = "projects/PROJECT_ID/regions/europe-west1/subnetworks/prod"
  service_account_email = "app-runtime@PROJECT_ID.iam.gserviceaccount.com"
  labels = {
    owner         = "platform"
    env           = "prod"
    "cost-center" = "security"
  }
}
