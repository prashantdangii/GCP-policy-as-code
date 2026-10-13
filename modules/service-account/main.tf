resource "google_service_account" "this" {
  project      = var.project_id
  account_id   = var.account_id
  display_name = var.display_name
  description  = var.description
}

resource "google_service_account_iam_member" "wif" {
  count              = var.wif_member == null ? 0 : 1
  service_account_id = google_service_account.this.name
  role               = "roles/iam.workloadIdentityUser"
  member             = var.wif_member
}
