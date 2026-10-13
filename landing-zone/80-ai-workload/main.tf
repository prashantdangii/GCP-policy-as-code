resource "google_project_service" "aiplatform" {
  count              = var.enable_ai_workload ? 1 : 0
  project            = var.project_id
  service            = "aiplatform.googleapis.com"
  disable_on_destroy = false
}

resource "google_service_account" "runtime" {
  count        = var.enable_ai_workload ? 1 : 0
  project      = var.project_id
  account_id   = "ai-runtime"
  display_name = "Vertex runtime"
  description  = "Least-privilege Vertex identity. No JSON keys. No Editor."
}

resource "google_project_iam_member" "user" {
  count   = var.enable_ai_workload ? 1 : 0
  project = var.project_id
  role    = "roles/aiplatform.user"
  member  = "serviceAccount:${google_service_account.runtime[0].email}"
}

resource "google_vertex_ai_endpoint" "sample" {
  #checkov:skip=CKV2_GCP_24:CMEK is optional on this sample endpoint so the stack can be planned before a key exists. Pass a key when the workload is enabled for real data.
  #checkov:skip=CKV2_GCP_33:Private egress is the NAT path documented in this stack. A Private Service Connect endpoint needs a published service and stays out of the default-off sample.
  count        = var.enable_ai_workload ? 1 : 0
  project      = var.project_id
  name         = "guardrails-sample"
  display_name = "guardrails-sample"
  location     = var.region
  description  = "Sample endpoint. Deploy a model only for a demo, then delete it."
  labels = {
    owner         = "platform"
    env           = "nonprod"
    "cost-center" = "security"
  }

  depends_on = [google_project_service.aiplatform]
}

module "egress" {
  count                   = var.enable_ai_workload && var.network_name != null ? 1 : 0
  source                  = "../../modules/firewall-rule"
  name                    = "allow-ai-private-google"
  project_id              = coalesce(var.network_project_id, var.project_id)
  network                 = coalesce(var.network_name, "unused")
  direction               = "EGRESS"
  action                  = "allow"
  protocol                = "tcp"
  ports                   = ["443"]
  ranges                  = ["199.36.153.8/30"]
  priority                = 900
  description             = "Vertex runtime may call Google APIs only through the private VIP"
  target_service_accounts = length(google_service_account.runtime) == 0 ? ["ai-runtime@example.com"] : [google_service_account.runtime[0].email]
}
