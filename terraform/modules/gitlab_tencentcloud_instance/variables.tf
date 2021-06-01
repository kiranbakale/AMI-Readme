variable "prefix" {}
variable "node_type" {}

variable "node_count" {
  default = 1
}

variable "instance_type" {
  default = "S3"
}

variable "image_id" {
  default = null
}

variable "security_group_ids" {
  type    = list(string)
  default = []
}

variable "vpc_id" {
  default = null
}

variable "subnet_id" {
  default = null
}

variable "ssh_key_name" {
  default = null
}

variable "disk_type" {
  default = "CLOUD_PREMIUM"
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
