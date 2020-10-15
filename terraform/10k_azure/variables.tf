variable "resource_group_name" {
  default = "gitlab-qa-10k"
}

variable "storage_account_name" {
  default = "gitlabqa10k"
}

variable "location" {
  default = "East US 2"
}

variable "prefix" {
  default = "gitlab-qa-10k"
}

variable "vm_admin_username" {
  default = "gitlab-qa"
}

variable "ssh_public_key_file_path" {
  default = "../../keys/performance/gitlab-qa-ssh.pub"
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

# Azure requires ID instead of IP to asign it to VM
variable "external_ip_name" {
  default = "gitlab-qa-10k-external-ip"
}
