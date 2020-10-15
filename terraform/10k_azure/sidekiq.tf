module "sidekiq" {
  source = "../modules/gitlab_azure_instance"

  prefix = "${var.prefix}"
  resource_group_name = "${var.resource_group_name}"
  node_type = "sidekiq"
  node_count = 4

  subnet_id = azurerm_subnet.gitlab.id
  vm_admin_username = "${var.vm_admin_username}"
  ssh_public_key_file_path = "${var.ssh_public_key_file_path}"
  size = "Standard_D4s_v3"
}

output "sidekiq" {
  value = module.sidekiq
}
