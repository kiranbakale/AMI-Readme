variable "prefix" {}
variable "node_type" {}
variable "resource_group_name" {}
variable "subnet_id" {}
variable "ssh_public_key_file_path" {}
variable "vm_admin_username" {}

variable "location" {
  default = "eastus2"
}

variable "node_count" {
  default = 1
}

variable "tags" {
  type = list(string)
  default = []
}

variable "external_ip_ids" {
  type = list(string)
  default = []
}

variable "size" {
  default = "Standard_D2s_v3"
}

variable "source_image_reference" {
  type = map
  default = {
      "publisher"  = "Canonical"
      "offer"  = "UbuntuServer"
      "sku"  = "18.04-LTS"
      "version"  = "latest"
  }
}

variable "disk_size" {
  default = "100"
}

variable "storage_account_type" {
  default = "Standard_LRS"
}

variable "label_secondaries" {
  default = false
}

variable "network_security_group" {
  default = ""
}
