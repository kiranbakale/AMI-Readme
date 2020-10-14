module "pgbouncer" {
  source = "../modules/gitlab_azure_instance"

  prefix = "${var.prefix}"
  resource_group_name = "${var.resource_group_name}"
  node_type = "pgbouncer"
  node_count = 3

  subnet_id = azurerm_subnet.gitlab.id
  ssh_public_key_file_path = "${var.ssh_public_key_file_path}"
  size = "Standard_F2s_v2"
}

output "pgbouncer" {
  value = module.pgbouncer
}
