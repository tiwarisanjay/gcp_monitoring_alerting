variable "project_id" {
  description = "The project ID where resources will be created"
  type        = string
}

variable "email_address" {
  description = "Email address for notifications. Optional if pagerduty_service_key is provided."
  type        = string
  default     = null
}

variable "pagerduty_service_key" {
  description = "The PagerDuty service key for notifications. Optional if email_address is provided."
  type        = string
  default     = null
  sensitive   = true
}

variable "threshold_requests" {
  description = "Threshold for secret access counts within a one-minute window"
  type        = number
  default     = 20
}
