module "key" {
  source        = "../.."
  project_id    = "PROJECT_ID"
  location      = "europe-west1"
  key_ring_name = "data"
  key_name      = "app"
  admin_member  = "group:grp-key-admins@example.com"
  user_member   = "serviceAccount:app-runtime@PROJECT_ID.iam.gserviceaccount.com"
}
