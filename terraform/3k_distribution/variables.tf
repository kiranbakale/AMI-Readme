variable "project" {
  default = "gitlab-qa-resources"
}

variable "credentials_file" {
  default = "../../keys/distribution/gitlab-qa-distribution-sa.json"
}

variable "region" {
  default = "us-east1"
}

variable "zone" {
  default = "us-east1-c"
}

variable "prefix" {
  default = "omnibus-3k"
}

variable "machine_image" {
  default = "ubuntu-1804-lts"
}

variable "external_ip" {
  default = "104.196.38.24"
}
