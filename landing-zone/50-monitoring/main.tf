locals {
  metrics = {
    iam-policy-changes = {
      description = "IAM SetIamPolicy calls"
      filter      = "protoPayload.methodName=\"SetIamPolicy\""
    }
    firewall-changes = {
      description = "Firewall rule create, patch, or delete"
      filter      = "protoPayload.methodName:(\"compute.firewalls.insert\" OR \"compute.firewalls.patch\" OR \"compute.firewalls.delete\")"
    }
    sa-key-creation = {
      description = "Service account key creation"
      filter      = "protoPayload.methodName=\"google.iam.admin.v1.CreateServiceAccountKey\""
    }
    org-policy-changes = {
      description = "Organization Policy writes"
      filter      = "protoPayload.serviceName=\"orgpolicy.googleapis.com\" AND protoPayload.methodName:(\"CreatePolicy\" OR \"UpdatePolicy\" OR \"DeletePolicy\")"
    }
    vpc-sc-violations = {
      description = "VPC Service Controls denials"
      filter      = "protoPayload.metadata.@type=\"type.googleapis.com/google.cloud.audit.VpcServiceControlAuditMetadata\""
    }
    logging-config-changes = {
      description = "Sink or exclusion changes, including disabled logging"
      filter      = "protoPayload.serviceName=\"logging.googleapis.com\" AND protoPayload.methodName:(\"UpdateSink\" OR \"DeleteSink\" OR \"UpdateExclusion\" OR \"DeleteExclusion\")"
    }
  }
}

resource "google_monitoring_notification_channel" "email" {
  project      = var.logging_project_id
  display_name = "security-email"
  type         = "email"
  labels = {
    email_address = var.notification_email
  }
}

resource "google_logging_metric" "security" {
  for_each    = local.metrics
  project     = var.logging_project_id
  name        = each.key
  filter      = each.value.filter
  description = each.value.description

  metric_descriptor {
    metric_kind = "DELTA"
    value_type  = "INT64"
    unit        = "1"
  }
}

resource "google_monitoring_alert_policy" "security" {
  for_each     = local.metrics
  project      = var.logging_project_id
  display_name = each.value.description
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = each.value.description
    condition_threshold {
      filter          = "resource.type=\"global\" AND metric.type=\"logging.googleapis.com/user/${each.key}\""
      comparison      = "COMPARISON_GT"
      threshold_value = 0
      duration        = "0s"

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.id]

  documentation {
    content   = "See queries/bigquery for the matching investigation query. Metric ${each.key}."
    mime_type = "text/markdown"
  }

  depends_on = [google_logging_metric.security]
}
