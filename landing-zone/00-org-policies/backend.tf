terraform {
  backend "gcs" {
    prefix = "00-org-policies"
  }
}
