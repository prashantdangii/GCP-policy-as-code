locals {
  subnets = {
    prod    = "10.10.0.0/20"
    nonprod = "10.20.0.0/20"
    shared  = "10.30.0.0/20"
  }
}

resource "google_compute_shared_vpc_host_project" "host" {
  project = var.network_project_id
}

resource "google_compute_network" "shared" {
  #checkov:skip=CKV2_GCP_18:Ingress is a hierarchical firewall policy plus modules/firewall-rule for IAP and health checks. The default network is not created.
  name                    = "shared-vpc"
  project                 = var.network_project_id
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  description             = "Custom-mode Shared VPC. No default network."
}

resource "google_compute_subnetwork" "env" {
  for_each                 = local.subnets
  name                     = "${each.key}-subnet"
  project                  = var.network_project_id
  region                   = var.region
  network                  = google_compute_network.shared.id
  ip_cidr_range            = each.value
  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = var.flow_log_sampling
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_shared_vpc_service_project" "service" {
  for_each        = toset(var.service_project_ids)
  host_project    = var.network_project_id
  service_project = each.value

  depends_on = [google_compute_shared_vpc_host_project.host]
}

resource "google_compute_router" "nat" {
  name    = "nat-router"
  project = var.network_project_id
  region  = var.region
  network = google_compute_network.shared.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "cloud-nat"
  project                            = var.network_project_id
  router                             = google_compute_router.nat.name
  region                             = var.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
