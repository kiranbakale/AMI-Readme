variable "prefix" {}
variable "node_type" {}

variable "node_count" {
  default = 1
}

variable "instance_type" {
  default = "ecs.n4.small"
}

variable "image_id" {
  default = null
}

variable "security_group_ids" {
  type    = list(string)
  default = []
}

variable "vswitch_id" {
  default = null
}

variable "ssh_key_name" {
  default = null
}

variable "disk_type" {
  default = "cloud_ssd"
}

variable "disk_size" {
  default = "100"
}

variable "label_secondaries" {
  default = false
}

variable "geo_site" {
  default = null
}

variable "geo_deployment" {
  default = null
}
