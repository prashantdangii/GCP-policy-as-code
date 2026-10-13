resource "google_pubsub_topic" "budget" {
  #checkov:skip=CKV_GCP_83:Budget alerts carry threshold notices, not customer data. CMEK stays optional so the topic can exist before a key ring does.
  project = var.project_id
  name    = "billing-budget-alerts"
}

resource "google_pubsub_topic_iam_member" "budget_publisher" {
  project = var.project_id
  topic   = google_pubsub_topic.budget.name
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${var.project_number}@gcp-sa-billing-budgets.iam.gserviceaccount.com"
}

resource "google_billing_budget" "landing_zone" {
  billing_account = var.billing_account_id
  display_name    = "guardrails-landing-zone"

  budget_filter {
    projects = length(var.monitored_projects) == 0 ? null : var.monitored_projects
  }

  amount {
    specified_amount {
      currency_code = var.currency_code
      units         = tostring(var.budget_amount)
    }
  }

  threshold_rules {
    threshold_percent = 0.5
  }
  threshold_rules {
    threshold_percent = 0.8
  }
  threshold_rules {
    threshold_percent = 1.0
  }

  all_updates_rule {
    pubsub_topic                     = google_pubsub_topic.budget.id
    monitoring_notification_channels = var.notification_channel_id == null ? [] : [var.notification_channel_id]
    disable_default_iam_recipients   = false
  }

  depends_on = [google_pubsub_topic_iam_member.budget_publisher]
}
