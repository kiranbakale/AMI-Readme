module "haproxy_external" {
  source = "../gitlab_azure_instance"

  prefix = var.prefix
  node_type = "haproxy-external"
  node_count = var.haproxy_external_node_count

  size = var.haproxy_external_size
  source_image_reference = var.source_image_reference
  disk_size = coalesce(var.haproxy_external_disk_size, var.default_disk_size)
  storage_account_type = coalesce(var.haproxy_external_storage_account_type, var.default_storage_account_type)

  resource_group_name = var.resource_group_name
  subnet_id = azurerm_subnet.gitlab.id
  vm_admin_username = var.vm_admin_username
  ssh_public_key_file_path = var.ssh_public_key_file_path
  location = var.location

  external_ip_names = var.haproxy_external_external_ip_names
  network_security_group = azurerm_network_security_group.haproxy

  geo_site = var.geo_site
  geo_deployment = var.geo_deployment
}

output "haproxy_external" {
  value = module.haproxy_external
}

module "haproxy_internal" {
  source = "../gitlab_azure_instance"

  prefix = var.prefix
  node_type = "haproxy-internal"
  node_count = var.haproxy_internal_node_count

  size = var.haproxy_internal_size
  source_image_reference = var.source_image_reference
  disk_size = coalesce(var.haproxy_internal_disk_size, var.default_disk_size)
  storage_account_type = coalesce(var.haproxy_internal_storage_account_type, var.default_storage_account_type)

  resource_group_name = var.resource_group_name
  subnet_id = azurerm_subnet.gitlab.id
  vm_admin_username = var.vm_admin_username
  ssh_public_key_file_path = var.ssh_public_key_file_path
  location = var.location

  geo_site = var.geo_site
  geo_deployment = var.geo_deployment
}

output "haproxy_internal" {
  value = module.haproxy_internal
}
