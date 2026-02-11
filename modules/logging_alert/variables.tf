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

variable "threshold_mb" {
  description = "The threshold in MB for logging byte writes"
  type        = number
  default     = 50
}
