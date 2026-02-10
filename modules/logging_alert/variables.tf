variable "project_id" {
  description = "The project ID where resources will be created"
  type        = string
}

variable "email_address" {
  description = "Email address for notifications"
  type        = string
  default     = "sanjay.tiwari@gmail.com"
}

variable "threshold_mb" {
  description = "The threshold in MB for logging byte writes"
  type        = number
  default     = 50
}
