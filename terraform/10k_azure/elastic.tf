module "elastic" {
  source = "../modules/gitlab_azure_instance"

  prefix = "${var.prefix}"
  resource_group_name = "${var.resource_group_name}"
  node_type = "elastic"
  node_count = 3

  storage_account_type = "Premium_LRS"
  disk_size = "512"

  subnet_id = azurerm_subnet.gitlab.id
  ssh_public_key_file_path = "${var.ssh_public_key_file_path}"
  size = "Standard_F16s_v2"
  label_secondaries = true
}

output "elastic" {
  value = module.elastic
}
