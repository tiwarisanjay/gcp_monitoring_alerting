terraform {
  backend "gcs" {
    bucket = "tf-state-bucket"
    prefix = "terraform/state/prod"
  }
}
