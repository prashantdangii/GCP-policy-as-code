module "bucket" {
  source     = "../.."
  name       = "project-prefix-app-data"
  project_id = "PROJECT_ID"
  location   = "eu"
  labels = {
    owner         = "platform"
    env           = "nonprod"
    "cost-center" = "security"
  }
}
