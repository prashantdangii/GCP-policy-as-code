resource "google_dns_managed_zone" "googleapis" {
  count       = var.enable_private_dns ? 1 : 0
  name        = "private-googleapis"
  project     = var.network_project_id
  dns_name    = "googleapis.com."
  description = "Sends Google API calls to private.googleapis.com instead of public VIPs."
  visibility  = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.shared.id
    }
  }
}

resource "google_dns_record_set" "private_googleapis" {
  count        = var.enable_private_dns ? 1 : 0
  name         = "private.googleapis.com."
  project      = var.network_project_id
  managed_zone = google_dns_managed_zone.googleapis[0].name
  type         = "A"
  ttl          = 300
  rrdatas      = ["199.36.153.8", "199.36.153.9", "199.36.153.10", "199.36.153.11"]
}

resource "google_dns_record_set" "wildcard_googleapis" {
  count        = var.enable_private_dns ? 1 : 0
  name         = "*.googleapis.com."
  project      = var.network_project_id
  managed_zone = google_dns_managed_zone.googleapis[0].name
  type         = "CNAME"
  ttl          = 300
  rrdatas      = ["private.googleapis.com."]
}
