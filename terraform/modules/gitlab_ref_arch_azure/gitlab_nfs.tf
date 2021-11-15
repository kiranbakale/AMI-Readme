module "gitlab_nfs" {
  source = "../gitlab_azure_instance"

  prefix     = var.prefix
  node_type  = "gitlab-nfs"
  node_count = var.gitlab_nfs_node_count

  size                   = var.gitlab_nfs_size
  source_image_reference = var.source_image_reference
  disk_size              = coalesce(var.gitlab_nfs_disk_size, var.default_disk_size)
  storage_account_type   = coalesce(var.gitlab_nfs_storage_account_type, var.default_storage_account_type)

  resource_group_name      = var.resource_group_name
  subnet_id                = azurerm_subnet.gitlab.id
  vm_admin_username        = var.vm_admin_username
  ssh_public_key_file_path = var.ssh_public_key_file_path
  location                 = var.location
  external_ip_type         = var.external_ip_type

  network_security_group = azurerm_network_security_group.ssh

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment
}

output "gitlab_nfs" {
  value = module.gitlab_nfs
}
