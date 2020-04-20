variable "project" {
  default = "gitlab-qa-50k-193234"
}

variable "credentials_file" {
  default = "../../keys/performance/serviceaccount-50k.json"
}

variable "region" {
  default = "us-east1"
}

variable "zone" {
  default = "us-east1-c"
}

variable "prefix" {
  default = "gitlab-qa-50k"
}

variable "machine_image" {
  default = "ubuntu-1804-lts"
}
