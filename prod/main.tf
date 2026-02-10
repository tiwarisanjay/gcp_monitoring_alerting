provider "google" {
  project = "sanjay_test_project_0001"
  region  = "us-central1"
}

module "logging_alert" {
  source = "../modules/logging_alert"

  project_id    = "sanjay_test_project_0001"
  email_address = "sanjay.tiwari@gmail.com"
  threshold_mb  = 50
}
