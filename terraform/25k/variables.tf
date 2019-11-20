variable "project" {
  default = "gitlab-qa-25k-bc38fe"
}

variable "credentials_file" {
  default = "../../secrets/serviceaccount-25k.json"
}

variable "region" {
  default = "us-east1"
}

variable "zone" {
  default = "us-east1-c"
}

variable "prefix" {
  default = "gitlab-qa-25k"
}

variable "machine_image" {
  default = "ubuntu-1804-lts"
}

variable "secrets_storage" {
  default = "gitlab-gitlab-qa-25k-secrets"
}
