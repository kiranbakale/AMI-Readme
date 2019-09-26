variable "prefix" {}
variable "node_type" {}
variable "ssh_public_key" {}
# variable "global_ip" {}

variable "node_count" {
  default = 1
}

variable "tags" {
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