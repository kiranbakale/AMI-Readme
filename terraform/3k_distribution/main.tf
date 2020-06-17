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
    bucket  = "omnibus-3k-terraform-state"
    credentials = "../../keys/distribution/gitlab-qa-distribution-sa.json"
  }
}
