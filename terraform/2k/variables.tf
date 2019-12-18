variable "project" {
  default = "gitlab-qa-2k-ca9f9e"
}

variable "credentials_file" {
  default = "../../secrets/serviceaccount-2k.json"
}

variable "region" {
  default = "us-east1"
}

variable "zone" {
  default = "us-east1-c"
}

variable "prefix" {
  default = "gitlab-qa-2k"
}

variable "machine_image" {
  default = "ubuntu-1804-lts"
}

variable "secrets_storage_bucket" {
  default = "gitlab-gitlab-qa-2k-secrets"
}
