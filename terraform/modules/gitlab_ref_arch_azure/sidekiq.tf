module "sidekiq" {
  source = "../gitlab_azure_instance"

  prefix = var.prefix
  node_type = "sidekiq"
  node_count = var.sidekiq_node_count

  size = var.sidekiq_size
  source_image_reference = var.source_image_reference
  disk_size = coalesce(var.sidekiq_disk_size, var.default_disk_size)
  storage_account_type = coalesce(var.sidekiq_storage_account_type, var.default_storage_account_type)

  resource_group_name = var.resource_group_name
  subnet_id = azurerm_subnet.gitlab.id
  vm_admin_username = var.vm_admin_username
  ssh_public_key_file_path = var.ssh_public_key_file_path
  location = var.location

  geo_site = var.geo_site
  geo_deployment = var.geo_deployment
}

output "sidekiq" {
  value = module.sidekiq
}