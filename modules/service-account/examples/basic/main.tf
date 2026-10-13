module "runtime" {
  source       = "../.."
  project_id   = "PROJECT_ID"
  account_id   = "app-runtime"
  display_name = "App runtime"
  description  = "Runtime identity for the sample app. No JSON keys."
}
