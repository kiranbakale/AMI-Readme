module "gitaly" {
  source = "../modules/gitlab_azure_instance"

  prefix = "${var.prefix}"
  resource_group_name = "${var.resource_group_name}"
  node_type = "gitaly"
  node_count = 2

  storage_account_type = "Premium_LRS"
  disk_size = "512"

  subnet_id = azurerm_subnet.gitlab.id
  vm_admin_username = "${var.vm_admin_username}"
  ssh_public_key_file_path = "${var.ssh_public_key_file_path}"
  size = "Standard_D16s_v3"
  label_secondaries = true
}

output "gitaly" {
  value = module.gitaly
}
