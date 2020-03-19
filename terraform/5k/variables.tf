variable "project" {
  default = "gitlab-qa-5k-0ee8fa"
}

variable "credentials_file" {
  default = "../../secrets/serviceaccount-5k.json"
}

variable "region" {
  default = "us-east1"
}

variable "zone" {
  default = "us-east1-c"
}

variable "prefix" {
  default = "gitlab-qa-5k"
}

variable "machine_image" {
  default = "ubuntu-1804-lts"
}
