variable "prefix" {}
variable "node_type" {}

variable "node_count" {
  default = 1
}

variable "tags" {
  type = list(string)
  default = []
}

variable "external_ips" {
  type = list(string)
  default = []
}

variable "machine_type" {
  default = "n1-standard-2"
}

variable "machine_image" {
  default = "ubuntu-1804-lts"
}

variable "disk_size" {
  default = "100"
}

variable "disk_type" {
  default = "pd-standard"
}

variable "label_secondaries" {
  default = false
}

variable "scopes" {
  type = list(string)
  default = []
}