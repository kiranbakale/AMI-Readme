provider "google" {
  version = "~> 2.20"
  credentials = file(var.credentials_file)

  project = var.project
  region  = var.region
  zone    = var.zone
}

terraform {
  required_version = "= 0.12.18"
  backend "gcs" {
    bucket  = "gitlab-qa-50k-k8s-terraform-state"
    credentials = "../../keys/performance/serviceaccount-50k-k8s.json"
  }
}