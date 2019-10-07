provider "google" {
  version = "~> 2.16"
  credentials = file(var.credentials_file)

  project = var.project
  region  = var.region
  zone    = var.zone
}

terraform {
  required_version = "~> 0.12.9"
  backend "gcs" {
    bucket  = "25k-terraform-state"
    credentials = "../../secrets/serviceaccount-25k.json"
  }
}