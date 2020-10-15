module "redis_cache" {
  source = "../modules/gitlab_azure_instance"

  prefix = "${var.prefix}"
  resource_group_name = "${var.resource_group_name}"
  node_type = "redis-cache"
  node_count = 3

  subnet_id = azurerm_subnet.gitlab.id
  vm_admin_username = "${var.vm_admin_username}"
  ssh_public_key_file_path = "${var.ssh_public_key_file_path}"
  size = "Standard_D4s_v3"
  label_secondaries = true
}

output "redis_cache" {
  value = module.redis_cache
}

module "redis_sentinel_cache" {
  source = "../modules/gitlab_azure_instance"

  prefix = "${var.prefix}"
  resource_group_name = "${var.resource_group_name}"
  node_type = "redis-sentinel-cache"
  node_count = 3

  subnet_id = azurerm_subnet.gitlab.id
  vm_admin_username = "${var.vm_admin_username}"
  ssh_public_key_file_path = "${var.ssh_public_key_file_path}"
  size = "Standard_B1ms"
  label_secondaries = true
}

output "redis_sentinel_cache" {
  value = module.redis_sentinel_cache
}

module "redis_persistent" {
  source = "../modules/gitlab_azure_instance"

  prefix = "${var.prefix}"
  resource_group_name = "${var.resource_group_name}"
  node_type = "redis-persistent"
  node_count = 3

  subnet_id = azurerm_subnet.gitlab.id
  vm_admin_username = "${var.vm_admin_username}"
  ssh_public_key_file_path = "${var.ssh_public_key_file_path}"
  size = "Standard_D4s_v3"
  label_secondaries = true
}

output "redis_persistent" {
  value = module.redis_persistent
}

module "redis_sentinel_persistent" {
  source = "../modules/gitlab_azure_instance"

  prefix = "${var.prefix}"
  resource_group_name = "${var.resource_group_name}"
  node_type = "redis-sentinel-persistent"
  node_count = 3

  subnet_id = azurerm_subnet.gitlab.id
  vm_admin_username = "${var.vm_admin_username}"
  ssh_public_key_file_path = "${var.ssh_public_key_file_path}"
  size = "Standard_B1ms"
  label_secondaries = true
}

output "redis_sentinel_persistent" {
  value = module.redis_sentinel_persistent
}
