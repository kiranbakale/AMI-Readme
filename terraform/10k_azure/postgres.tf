module "postgres" {
  source = "../modules/gitlab_azure_instance"

  prefix = "${var.prefix}"
  resource_group_name = "${var.resource_group_name}"
  node_type = "postgres"
  node_count = 3

  subnet_id = azurerm_subnet.gitlab.id
  ssh_public_key_file_path = "${var.ssh_public_key_file_path}"
  size = "Standard_D4s_v3"
  label_secondaries = true
}

output "postgres" {
  value = module.postgres
}
