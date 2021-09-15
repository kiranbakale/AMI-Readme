variable "prefix" {}
variable "node_type" {}

variable "node_count" {
  default = 1
}

variable "elastic_ip_allocation_ids" {
  type = list(string)
  default = []
}

variable "ami_id" {
  default = null
}

variable "iam_instance_profile" {
  default = null
}

variable "instance_type" {
  default = "t3.micro"
}

variable "security_group_ids" {
  type = list(string)
  default = []
}

variable "ssh_key_name" {
  default = null
}

variable "disk_type" {
  default = "gp3"
}

variable "disk_size" {
  default = "100"
}

variable "disk_iops" {
  default = null
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

variable "subnet_ids" {
  default = null
}
