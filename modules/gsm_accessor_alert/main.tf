resource "google_monitoring_notification_channel" "email" {
  count        = var.email_address != null ? 1 : 0
  display_name = "Email Notification Channel"
  type         = "email"
  project      = var.project_id
  labels = {
    email_address = var.email_address
  }
}

resource "google_monitoring_notification_channel" "pagerduty" {
  count        = var.pagerduty_service_key != null ? 1 : 0
  display_name = "PagerDuty Notification Channel"
  type         = "pagerduty"
  project      = var.project_id
  labels = {
    service_key = var.pagerduty_service_key
  }
}

locals {
  notification_channels = concat(
    [for c in google_monitoring_notification_channel.email : c.name],
    [for c in google_monitoring_notification_channel.pagerduty : c.name]
  )
}

resource "google_monitoring_alert_policy" "gsm_accessor_alert" {
  display_name = "Secret Manager excessive access (> ${var.threshold_requests} accesses/min)"
  combiner     = "OR"
  project      = var.project_id

  conditions {
    display_name = "Secret access > ${var.threshold_requests} in 1 minute"

    condition_threshold {
      filter = <<-EOT
        resource.type="secretmanager_secret" AND
        metric.type="secretmanager.googleapis.com/api/request_count" AND
        metric.labels.api_method="google.cloud.secretmanager.v1.SecretManagerService.AccessSecretVersion"
      EOT

      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = var.threshold_requests
      trigger {
        count = 1
      }

      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_DELTA"
      }

      cross_series_reducer = "REDUCE_SUM"
      group_by_fields      = []
    }
  }

  notification_channels = local.notification_channels

  lifecycle {
    precondition {
      condition     = length(local.notification_channels) > 0
      error_message = "At least one notification channel (email_address or pagerduty_service_key) must be provided."
    }
  }
}
