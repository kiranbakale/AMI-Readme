module "gitlab_rails" {
  source = "../modules/gitlab_azure_instance"

  prefix = "${var.prefix}"
  resource_group_name = "${var.resource_group_name}"
  node_type = "gitlab-rails"
  node_count = 3

  subnet_id = azurerm_subnet.gitlab.id
  ssh_public_key_file_path = "${var.ssh_public_key_file_path}"
  size = "Standard_F32s_v2"
  label_secondaries = true
}

output "gitlab_rails" {
  value = module.gitlab_rails
}
