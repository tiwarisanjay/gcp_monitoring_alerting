output "alert_policy_id" {
  description = "The ID of the created alert policy"
  value       = google_monitoring_alert_policy.logging_byte_writes.id
}

output "notification_channel_id" {
  description = "The ID of the created notification channel"
  value       = google_monitoring_notification_channel.email.id
}
