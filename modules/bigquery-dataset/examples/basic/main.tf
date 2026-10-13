module "dataset" {
  source     = "../.."
  dataset_id = "app_analytics"
  project_id = "PROJECT_ID"
  location   = "EU"
  labels = {
    owner         = "platform"
    env           = "prod"
    "cost-center" = "security"
  }
  authorized_groups = {
    "grp-analysts@example.com" = "roles/bigquery.dataViewer"
  }
}
