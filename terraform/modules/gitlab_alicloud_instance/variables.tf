variable "prefix" {
  type = string
}

variable "node_type" {
  type = string
}

variable "node_count" {
  type    = number
  default = 1
}

variable "instance_type" {
  type    = string
  default = "ecs.n4.small"
}

variable "image_id" {
  type    = string
  default = null
}

variable "security_group_ids" {
  type    = list(string)
  default = []
}

variable "vswitch_id" {
  type    = string
  default = null
}

variable "ssh_key_name" {
  type    = string
  default = null
}

variable "disk_type" {
  type    = string
  default = "cloud_ssd"
}

variable "disk_size" {
  type    = string
  default = "100"
}

variable "label_secondaries" {
  type    = bool
  default = false
}

variable "geo_site" {
  type    = string
  default = null
}

variable "geo_deployment" {
  type    = string
  default = null
}
