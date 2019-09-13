variable "project" {
  default = "gitlab-qa-resources"
}

variable "credentials_file" {}
variable "ssh_public_key" {}

variable "region" {
  default = "us-central1"
}

variable "zone" {
  default = "us-central1-c"
}

variable "prefix" {
  default = "gitlab-10k-testbed"
}
