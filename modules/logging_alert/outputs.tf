output "alert_policy_id" {
  description = "The ID of the created alert policy"
  value       = google_monitoring_alert_policy.logging_byte_writes.id
}

output "email_notification_channel_id" {
  description = "The ID of the email notification channel (if created)"
  value       = length(google_monitoring_notification_channel.email) > 0 ? google_monitoring_notification_channel.email[0].id : null
}

output "pagerduty_notification_channel_id" {
  description = "The ID of the PagerDuty notification channel (if created)"
  value       = length(google_monitoring_notification_channel.pagerduty) > 0 ? google_monitoring_notification_channel.pagerduty[0].id : null
}
