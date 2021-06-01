module "redis" {
  source = "../gitlab_alicloud_instance"

  prefix     = var.prefix
  node_type  = "redis"
  node_count = var.redis_node_count

  instance_type = var.redis_instance_type
  image_id      = coalesce(var.image_id, data.alicloud_images.ubuntu_18_04.id)
  disk_size     = coalesce(var.redis_disk_size, var.default_disk_size)
  disk_type     = coalesce(var.redis_disk_type, var.default_disk_type)

  security_group_ids = [alicloud_security_group.gitlab_external_ssh.id]
  vswitch_id         = alicloud_vswitch.vswitch.id

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true
}

output "redis" {
  value = module.redis
}

# Redis Separate Cache

module "redis_cache" {
  source = "../gitlab_alicloud_instance"

  prefix     = var.prefix
  node_type  = "redis-cache"
  node_count = var.redis_cache_node_count

  instance_type = var.redis_cache_instance_type
  image_id      = coalesce(var.image_id, data.alicloud_images.ubuntu_18_04.id)
  disk_size     = coalesce(var.redis_cache_disk_size, var.default_disk_size)
  disk_type     = coalesce(var.redis_cache_disk_type, var.default_disk_type)

  security_group_ids = [alicloud_security_group.gitlab_external_ssh.id]
  vswitch_id         = alicloud_vswitch.vswitch.id

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true
}

output "redis_cache" {
  value = module.redis_cache
}

module "redis_sentinel_cache" {
  source = "../gitlab_alicloud_instance"

  prefix     = var.prefix
  node_type  = "redis-sentinel-cache"
  node_count = var.redis_sentinel_cache_node_count

  instance_type = var.redis_sentinel_cache_instance_type
  image_id      = coalesce(var.image_id, data.alicloud_images.ubuntu_18_04.id)
  disk_size     = coalesce(var.redis_sentinel_cache_disk_size, var.default_disk_size)
  disk_type     = coalesce(var.redis_sentinel_cache_disk_type, var.default_disk_type)

  security_group_ids = [alicloud_security_group.gitlab_external_ssh.id]
  vswitch_id         = alicloud_vswitch.vswitch.id

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true
}

output "redis_sentinel_cache" {
  value = module.redis_sentinel_cache
}

module "redis_persistent" {
  source = "../gitlab_alicloud_instance"

  prefix     = var.prefix
  node_type  = "redis-persistent"
  node_count = var.redis_persistent_node_count

  instance_type = var.redis_persistent_instance_type
  image_id      = coalesce(var.image_id, data.alicloud_images.ubuntu_18_04.id)
  disk_size     = coalesce(var.redis_persistent_disk_size, var.default_disk_size)
  disk_type     = coalesce(var.redis_persistent_disk_type, var.default_disk_type)

  security_group_ids = [alicloud_security_group.gitlab_external_ssh.id]
  vswitch_id         = alicloud_vswitch.vswitch.id

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true
}

output "redis_persistent" {
  value = module.redis_persistent
}

module "redis_sentinel_persistent" {
  source = "../gitlab_alicloud_instance"

  prefix     = var.prefix
  node_type  = "redis-sentinel-persistent"
  node_count = var.redis_sentinel_persistent_node_count

  instance_type = var.redis_sentinel_persistent_instance_type
  image_id      = coalesce(var.image_id, data.alicloud_images.ubuntu_18_04.id)
  disk_size     = coalesce(var.redis_sentinel_persistent_disk_size, var.default_disk_size)
  disk_type     = coalesce(var.redis_sentinel_persistent_disk_type, var.default_disk_type)

  security_group_ids = [alicloud_security_group.gitlab_external_ssh.id]
  vswitch_id         = alicloud_vswitch.vswitch.id

  geo_site       = var.geo_site
  geo_deployment = var.geo_deployment

  label_secondaries = true
}

output "redis_sentinel_persistent" {
  value = module.redis_sentinel_persistent
}
