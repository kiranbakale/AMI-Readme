variable "project" {
  default = "gitlab-qa-distribution-35632a"
}

variable "credentials_file" {
  default = "../../../keys/distribution/gitlab-qa-distribution-sa.json"
}

variable "region" {
  default = "europe-west4"
}

variable "zone" {
  default = "europe-west4-a"
}

variable "prefix" {
  default = "geo-1k-secondary"
}

variable "machine_image" {
  default = "ubuntu-1804-lts"
}

variable "external_ip" {
  default = "34.90.198.213"
}

variable "geo_site" {
  default = "geo-secondary-site"
}

variable "geo_deployment" {
  default = "geo-1k-test"
}