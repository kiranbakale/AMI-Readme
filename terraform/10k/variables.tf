variable "project" {
  default = "gitlab-qa-10k-cd77c7"
}

variable "credentials_file" {
  default = "../../secrets/serviceaccount-10k.json"
}

variable "region" {
  default = "us-east1"
}

variable "zone" {
  default = "us-east1-c"
}

variable "prefix" {
  default = "gitlab-qa-10k"
}

variable "secrets_storage_bucket" {
  default = "gitlab-gitlab-qa-10k-secrets"
}