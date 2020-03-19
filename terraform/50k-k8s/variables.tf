variable "project" {
  default = "gitlab-qa-50k-k8s-799916"
}

variable "credentials_file" {
  default = "../../secrets/serviceaccount-50k-k8s.json"
}

variable "region" {
  default = "us-east1"
}

variable "zone" {
  default = "us-east1-c"
}

variable "prefix" {
  default = "gitlab-qa-50k-k8s"
}

variable "machine_image" {
  default = "ubuntu-1804-lts"
}
