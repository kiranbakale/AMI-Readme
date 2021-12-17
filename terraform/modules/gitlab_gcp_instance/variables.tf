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

variable "tags" {
  type    = list(string)
  default = []
}

variable "external_ips" {
  type    = list(string)
  default = []
}

variable "machine_type" {
  type    = string
  default = "n1-standard-2"
}

variable "machine_image" {
  type    = string
  default = "ubuntu-1804-lts"
}

variable "disk_size" {
  type    = string
  default = "100"
}

variable "disk_type" {
  type    = string
  default = "pd-standard"
}

variable "label_secondaries" {
  type    = bool
  default = false
}

variable "scopes" {
  type    = list(string)
  default = []
}

variable "geo_site" {
  type    = string
  default = null
}

variable "geo_deployment" {
  type    = string
  default = null
}

variable "disks" {
  type    = list(any)
  default = []
}

variable "vpc" {
  type    = string
  default = "default"
}

variable "subnet" {
  type    = string
  default = "default"
}

variable "zones" {
  type    = list(any)
  default = null
}

variable "setup_external_ip" {
  type    = bool
  default = true
}

variable "name_override" {
  type    = string
  default = null
}

variable "additional_labels" {
  type    = map(any)
  default = {}
}

variable "allow_stopping_for_update" {
  type    = bool
  default = true
}

variable "machine_secure_boot" {
  type    = bool
  default = false
}