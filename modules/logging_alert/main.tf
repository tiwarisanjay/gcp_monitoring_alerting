resource "google_monitoring_notification_channel" "email" {
  display_name = "Email Notification Channel"
  type         = "email"
  project      = var.project_id
  labels = {
    email_address = var.email_address
  }
}

resource "google_monitoring_alert_policy" "logging_byte_writes" {
  display_name = "High Logging Byte Write"
  combiner     = "OR"
  project      = var.project_id

  conditions {
    display_name = "Logging Byte Writes > ${var.threshold_mb}MB"
    condition_threshold {
      filter     = "resource.type = \"logging_bucket\" AND resource.labels.bucket_name = \"_default\" AND metric.type = \"logging.googleapis.com/byte_count\""
      duration   = "300s"
      
      comparison = "COMPARISON_GT"
      
      # MB to Bytes: 50 * 1024 * 1024 = 52428800
      threshold_value = var.threshold_mb * 1024 * 1024
      
      aggregations {
        alignment_period   = "300s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

  notification_channels = [google_monitoring_notification_channel.email.name]
}
