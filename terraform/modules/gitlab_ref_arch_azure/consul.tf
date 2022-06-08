module "consul" {
  source = "../gitlab_azure_instance"

  prefix          = var.prefix
  node_type       = "consul"
  node_count      = var.consul_node_count
  additional_tags = var.additional_tags

  size                   = var.consul_size
  source_image_reference = var.source_image_reference
  disk_size              = coalesce(var.consul_disk_size, var.default_disk_size)
  storage_account_type   = coalesce(var.consul_storage_account_type, var.default_storage_account_type)

  resource_group_name = var.resource_group_name
  subnet_id           = azurerm_subnet.gitlab.id
  vm_admin_username   = var.vm_admin_username
  ssh_public_key      = var.ssh_public_key != null ? var.ssh_public_key : file(var.ssh_public_key_file_path)
  location            = var.location
  external_ip_type    = var.external_ip_type
  setup_external_ip   = var.setup_external_ips

  application_security_group = azurerm_application_security_group.ssh

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment
}

output "consul" {
  value = module.consul
}
